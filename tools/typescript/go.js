"use strict";
exports.__esModule = true;
var fs = require("fs");
var ts = require("typescript");
var Consts = [];
var seenConstTypes = new Map();
var Structs = [];
var Types = [];
// Used in printing the AST
var seenThings = new Map();
function seenAdd(x) {
    seenThings[x] = (seenThings[x] === undefined ? 1 : seenThings[x] + 1);
}
var dir = process.env['HOME'];
var fnames = [
    "/vscode-languageserver-node/protocol/src/protocol.ts",
    "/vscode-languageserver-node/types/src/main.ts"
];
var outFname = '/tmp/tsprotocol.go';
var fda, fdb, fde; // file descriptors
function createOutputFiles() {
    fda = fs.openSync('/tmp/ts-a', 'w'); // dump of AST
    fdb = fs.openSync('/tmp/ts-b', 'w'); // unused, for debugging
    fde = fs.openSync(outFname, 'w'); // generated Go
}
function pra(s) {
    return (fs.writeSync(fda, s));
}
function prgo(s) {
    return (fs.writeSync(fde, s));
}
function generate(files, options) {
    var program = ts.createProgram(files, options);
    program.getTypeChecker(); // used for side-effects
    // dump the ast, for debugging
    for (var _i = 0, _a = program.getSourceFiles(); _i < _a.length; _i++) {
        var sourceFile = _a[_i];
        if (!sourceFile.isDeclarationFile) {
            // walk the tree to do stuff
            ts.forEachChild(sourceFile, describe);
        }
    }
    pra('\n');
    for (var _b = 0, _c = Object.keys(seenThings).sort(); _b < _c.length; _b++) {
        var key = _c[_b];
        pra(key + ": " + seenThings[key] + "\n");
    }
    // visit every sourceFile in the program, generating types
    for (var _d = 0, _e = program.getSourceFiles(); _d < _e.length; _d++) {
        var sourceFile = _e[_d];
        if (!sourceFile.isDeclarationFile) {
            ts.forEachChild(sourceFile, genTypes);
        }
    }
    return;
    function genTypes(node) {
        // Ignore top-level items with no output
        if (ts.isExpressionStatement(node) || ts.isFunctionDeclaration(node) ||
            ts.isImportDeclaration(node) || ts.isVariableStatement(node) ||
            ts.isExportDeclaration(node) ||
            node.kind == ts.SyntaxKind.EndOfFileToken) {
            return;
        }
        if (ts.isInterfaceDeclaration(node)) {
            doInterface(node);
            return;
        }
        else if (ts.isTypeAliasDeclaration(node)) {
            doTypeAlias(node);
        }
        else if (ts.isModuleDeclaration(node)) {
            doModuleDeclaration(node);
        }
        else if (ts.isEnumDeclaration(node)) {
            doEnumDecl(node);
        }
        else if (ts.isClassDeclaration(node)) {
            doClassDeclaration(node);
        }
        else {
            throw new Error("unexpected " + ts.SyntaxKind[node.kind] + " " + loc(node));
        }
    }
    function doClassDeclaration(node) {
        var id;
        var props = new Array();
        var extend;
        var bad = false;
        node.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n;
                return;
            }
            if (ts.isPropertyDeclaration(n)) {
                props.push(n);
                return;
            }
            if (n.kind == ts.SyntaxKind.ExportKeyword) {
                return;
            }
            if (n.kind == ts.SyntaxKind.Constructor || ts.isMethodDeclaration(n) ||
                ts.isGetAccessor(n) || ts.isTypeParameterDeclaration(n)) {
                bad = true;
                return;
            }
            if (ts.isHeritageClause(n)) {
                extend = n;
                return;
            }
            throw new Error("doClass " + loc(n) + " " + kinds(n));
        });
        if (bad) {
            // the class is not useful for Go.
            return;
        } // might we want the PropertyDecls? (don't think so)
        var fields = [];
        for (var _i = 0, props_1 = props; _i < props_1.length; _i++) {
            var pr = props_1[_i];
            fields.push(fromPropDecl(pr));
        }
        var ans = {
            me: node,
            name: toGoName(getText(id)),
            embeds: heritageStrs(extend),
            fields: fields
        };
        Structs.push(ans);
    }
    function fromPropDecl(node) {
        var id;
        var opt = false;
        var typ;
        node.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n;
                return;
            }
            if (n.kind == ts.SyntaxKind.QuestionToken) {
                opt = true;
                return;
            }
            if (typ != undefined)
                throw new Error("fromPropDecl too long " + loc(node));
            typ = n;
        });
        var goType = computeType(typ).goType;
        var ans = {
            me: node,
            id: id,
            goName: toGoName(getText(id)),
            optional: opt,
            goType: goType,
            json: "`json:\"" + id.text + (opt ? ',omitempty' : '') + "\"`"
        };
        return ans;
    }
    function doInterface(node) {
        // name: Identifier;
        // typeParameters?: NodeArray<TypeParameterDeclaration>;
        // heritageClauses?: NodeArray<HeritageClause>;
        // members: NodeArray<TypeElement>;
        // find the Identifier from children
        // process the PropertySignature children
        // the members might have generic info, but so do the children
        var id;
        var extend;
        var generid;
        var properties = new Array();
        var index; // generate some sort of map
        node.forEachChild(function (n) {
            if (n.kind == ts.SyntaxKind.ExportKeyword || ts.isMethodSignature(n)) {
                // ignore
            }
            else if (ts.isIdentifier(n)) {
                id = n;
            }
            else if (ts.isHeritageClause(n)) {
                extend = n;
            }
            else if (ts.isTypeParameterDeclaration(n)) {
                // Act as if this is <T = any>
                generid = n.name;
            }
            else if (ts.isPropertySignature(n)) {
                properties.push(n);
            }
            else if (ts.isIndexSignatureDeclaration(n)) {
                if (index !== undefined) {
                    throw new Error(loc(n) + " multiple index expressions");
                }
                index = n;
            }
            else {
                throw new Error(loc(n) + " doInterface " + ts.SyntaxKind[n.kind] + " ");
            }
        });
        var fields = [];
        for (var _i = 0, properties_1 = properties; _i < properties_1.length; _i++) {
            var p = properties_1[_i];
            fields.push(genProp(p, generid));
        }
        if (index != undefined) {
            fields.push(fromIndexSignature(index));
        }
        var ans = {
            me: node,
            name: toGoName(getText(id)),
            embeds: heritageStrs(extend),
            fields: fields
        };
        Structs.push(ans);
    }
    function heritageStrs(node) {
        // ExpressionWithTypeArguments+, and each is an Identifier
        var ans = [];
        if (node == undefined) {
            return ans;
        }
        var x = [];
        node.forEachChild(function (n) {
            if (ts.isExpressionWithTypeArguments(n))
                x.push(n);
        });
        var _loop_1 = function (p) {
            p.forEachChild(function (n) {
                if (ts.isIdentifier(n)) {
                    ans.push(toGoName(getText(n)));
                    return;
                }
                if (ts.isTypeReferenceNode(n)) {
                    // don't want these, ignore them
                    return;
                }
                throw new Error("expected Identifier " + loc(n) + " " + kinds(p) + " ");
            });
        };
        for (var _i = 0, x_1 = x; _i < x_1.length; _i++) {
            var p = x_1[_i];
            _loop_1(p);
        }
        return ans;
    }
    function genProp(node, gen) {
        var id;
        var thing;
        var opt = false;
        node.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n;
            }
            else if (n.kind == ts.SyntaxKind.QuestionToken) {
                opt = true;
            }
            else if (n.kind == ts.SyntaxKind.ReadonlyKeyword) {
                return;
            }
            else {
                if (thing !== undefined) {
                    throw new Error(loc(n) + " weird");
                }
                thing = n;
            }
        });
        var goName = toGoName(id.text);
        var _a = computeType(thing), goType = _a.goType, gostuff = _a.gostuff, optional = _a.optional, fields = _a.fields;
        // Generics
        if (gen && gen.text == goType)
            goType = 'interface{}';
        opt = opt || optional;
        var ans = {
            me: node,
            id: id,
            goName: goName,
            optional: opt,
            goType: goType,
            gostuff: gostuff,
            substruct: fields,
            json: "`json:\"" + id.text + (opt ? ',omitempty' : '') + "\"`"
        };
        // Rather than checking that goName is a const type, just do
        switch (goType) {
            case 'CompletionItemKind':
            case 'TextDocumentSyncKind':
            case 'CodeActionKind':
            case 'InsertTextFormat': // float64
            case 'DiagnosticSeverity':
                ans.optional = false;
        }
        return ans;
    }
    function doModuleDeclaration(node) {
        // Export Identifier ModuleBlock
        var id;
        var mb;
        node.forEachChild(function (n) {
            if ((ts.isIdentifier(n) && (id = n)) ||
                (ts.isModuleBlock(n) && mb === undefined && (mb = n)) ||
                (n.kind == ts.SyntaxKind.ExportKeyword)) {
                return;
            }
            throw new Error("doModuleDecl " + loc(n) + " " + ts.SyntaxKind[n.kind]);
        });
        // Don't want FunctionDeclarations
        // mb has VariableStatement and useless TypeAliasDeclaration
        // some of the VariableStatement are consts, and want their comments
        // and each VariableStatement is Export, VariableDeclarationList
        // and each VariableDeclarationList is a single VariableDeclaration
        var v = [];
        function f(n) {
            if (ts.isVariableDeclaration(n)) {
                v.push(n);
                return;
            }
            if (ts.isFunctionDeclaration(n)) {
                return;
            }
            n.forEachChild(f);
        }
        f(node);
        for (var _i = 0, v_1 = v; _i < v_1.length; _i++) {
            var vx = v_1[_i];
            if (hasNewExpression(vx)) {
                return;
            }
            buildConst(getText(id), vx);
        }
    }
    function buildConst(tname, node) {
        // node is Identifier, optional-goo, (FirstLiteralToken|StringLiteral)
        var id;
        var str;
        var first;
        node.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n;
            }
            else if (ts.isStringLiteral(n)) {
                str = getText(n);
            }
            else if (n.kind == ts.SyntaxKind.FirstLiteralToken) {
                first = getText(n);
            }
        });
        if (str == undefined && first == undefined) {
            return;
        } // various
        var ty = (str != undefined) ? 'string' : 'float64';
        var val = (str != undefined) ? str.replace(/'/g, '"') : first;
        var name = toGoName(getText(id));
        var c = {
            typeName: tname,
            goType: ty,
            me: node.parent.parent,
            name: name,
            value: val
        };
        Consts.push(c);
        return c;
    }
    // is node an ancestor of a NewExpression
    function hasNewExpression(n) {
        var ans = false;
        n.forEachChild(function (n) {
            if (ts.isNewExpression(n))
                ans = true;
        });
        return ans;
    }
    function doEnumDecl(node) {
        // Generates Consts. Identifier EnumMember+
        // EnumMember: Identifier StringLiteral
        var id;
        var mems = [];
        node.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n; // check for uniqueness?
            }
            else if (ts.isEnumMember(n)) {
                mems.push(n);
            }
            else if (n.kind != ts.SyntaxKind.ExportKeyword) {
                throw new Error("doEnumDecl " + ts.SyntaxKind[n.kind] + " " + loc(n));
            }
        });
        var _loop_2 = function (m) {
            var name_1;
            var value;
            m.forEachChild(function (n) {
                if (ts.isIdentifier(n)) {
                    name_1 = getText(n);
                }
                else if (ts.isStringLiteral(n)) {
                    value = getText(n).replace(/'/g, '"');
                }
                else {
                    throw new Error("in doEnumDecl " + ts.SyntaxKind[n.kind] + " " + loc(n));
                }
            });
            var ans = {
                typeName: getText(id),
                goType: 'string',
                me: m,
                name: name_1,
                value: value
            };
            Consts.push(ans);
        };
        for (var _i = 0, mems_1 = mems; _i < mems_1.length; _i++) {
            var m = mems_1[_i];
            _loop_2(m);
        }
    }
    // top-level TypeAlias
    function doTypeAlias(node) {
        // these are all Export Identifier alias
        var id;
        var alias;
        var genid; // <T>, but we don't care
        node.forEachChild(function (n) {
            if ((ts.isIdentifier(n) && (id = n)) ||
                (n.kind == ts.SyntaxKind.ExportKeyword) ||
                ts.isTypeParameterDeclaration(n) && (genid = n) ||
                (alias === undefined && (alias = n))) {
                return;
            }
            throw new Error("doTypeAlias " + loc(n) + " " + ts.SyntaxKind[n.kind]);
        });
        var ans = {
            me: node,
            id: id,
            goName: toGoName(getText(id)),
            goType: '?',
            stuff: ''
        };
        if (id.text.indexOf('--') != -1) {
            return;
        } // don't care
        if (ts.isUnionTypeNode(alias)) {
            ans.goType = weirdUnionType(alias);
            if (ans.goType == undefined) { // these are redundant
                return;
            }
            Types.push(ans);
            return;
        }
        if (ts.isIntersectionTypeNode(alias)) { // a Struct, not a Type
            var embeds_1 = [];
            alias.forEachChild(function (n) {
                if (ts.isTypeReferenceNode(n)) {
                    embeds_1.push(toGoName(computeType(n).goType));
                }
                else
                    throw new Error("expected TypeRef " + ts.SyntaxKind[n.kind] + " " + loc(n));
            });
            var ans_1 = { me: node, name: toGoName(getText(id)), embeds: embeds_1 };
            Structs.push(ans_1);
            return;
        }
        if (ts.isArrayTypeNode(alias)) { // []DocumentFilter
            ans.goType = '[]DocumentFilter';
            Types.push(ans);
            return;
        }
        if (ts.isLiteralTypeNode(alias)) {
            return; // type A = 1, so nope
        }
        if (ts.isTypeReferenceNode(alias)) {
            ans.goType = computeType(alias).goType;
            if (ans.goType.match(/und/) != null)
                throw new Error('396');
            Types.push(ans); // type A B
            return;
        }
        if (alias.kind == ts.SyntaxKind.StringKeyword) { // type A string
            ans.goType = 'string';
            Types.push(ans);
            return;
        }
        throw new Error("in doTypeAlias " + loc(node) + " " + kinds(node) + " " + ts.SyntaxKind[alias.kind] + "\n");
    }
    // extract the one useful but weird case ()
    function weirdUnionType(node) {
        var bad = false;
        var tl = [];
        node.forEachChild(function (n) {
            if (ts.isTypeLiteralNode(n)) {
                tl.push(n);
            }
            else
                bad = true;
        });
        if (bad)
            return; // none of these are useful (so far)
        var x = computeType(tl[0]);
        x.fields[0].json = x.fields[0].json.replace(/"`/, ',omitempty"`');
        var out = [];
        for (var _i = 0, _a = x.fields; _i < _a.length; _i++) {
            var f = _a[_i];
            out.push(strField(f));
        }
        out.push('}\n');
        var ans = 'struct {\n'.concat.apply('struct {\n', out);
        return ans;
    }
    function computeType(node) {
        switch (node.kind) {
            case ts.SyntaxKind.AnyKeyword:
            case ts.SyntaxKind.ObjectKeyword:
                return { goType: 'interface{}' };
            case ts.SyntaxKind.BooleanKeyword:
                return { goType: 'bool' };
            case ts.SyntaxKind.NumberKeyword:
                return { goType: 'float64' };
            case ts.SyntaxKind.StringKeyword:
                return { goType: 'string' };
            case ts.SyntaxKind.NullKeyword:
            case ts.SyntaxKind.UndefinedKeyword:
                return { goType: 'nil' };
        }
        if (ts.isArrayTypeNode(node)) {
            var _a = computeType(node.elementType), goType = _a.goType, gostuff = _a.gostuff, optional = _a.optional;
            return ({ goType: '[]' + goType, gostuff: gostuff, optional: optional });
        }
        else if (ts.isTypeReferenceNode(node)) {
            // typeArguments?: NodeArray<TypeNode>;typeName: EntityName;
            // typeArguments won't show up in the generated Go
            // EntityName: Identifier|QualifiedName
            var tn = node.typeName;
            if (ts.isQualifiedName(tn)) {
                throw new Error("qualified name at " + loc(node));
            }
            else if (ts.isIdentifier(tn)) {
                return { goType: tn.text };
            }
            else {
                throw new Error("expected identifier got " + ts.SyntaxKind[node.typeName.kind] + " at " + loc(tn));
            }
        }
        else if (ts.isLiteralTypeNode(node)) {
            // string|float64 (are there other possibilities?)
            var txt = getText(node);
            var typ = 'float64';
            if (txt.charAt(0) == '\'') {
                typ = 'string';
            }
            return { goType: typ, gostuff: getText(node) };
        }
        else if (ts.isTypeLiteralNode(node)) {
            var x_3 = [];
            var indexCnt_1 = 0;
            node.forEachChild(function (n) {
                if (ts.isPropertySignature(n)) {
                    x_3.push(genProp(n, undefined));
                    return;
                }
                else if (ts.isIndexSignatureDeclaration(n)) {
                    indexCnt_1++;
                    x_3.push(fromIndexSignature(n));
                    return;
                }
                throw new Error(loc(n) + " gotype " + ts.SyntaxKind[n.kind] + ", not expected");
            });
            if (indexCnt_1 > 0) {
                if (indexCnt_1 != 1 || x_3.length != 1)
                    throw new Error("undexpected Index " + loc(x_3[0].me));
                // instead of {map...} just the map
                return ({ goType: x_3[0].goType, gostuff: x_3[0].gostuff });
            }
            return ({ goType: 'embedded!', fields: x_3 });
        }
        else if (ts.isUnionTypeNode(node)) {
            var x_4 = new Array();
            node.forEachChild(function (n) { x_4.push(computeType(n)); });
            if (x_4.length == 2 && x_4[1].goType == 'nil') {
                return x_4[0]; // make it optional somehow? TODO
            }
            if (x_4[0].goType == 'bool') { // take it
                return ({ goType: 'bool', gostuff: getText(node) });
            }
            // these are special cases from looking at the source
            var gostuff = getText(node);
            if (x_4[0].goType == "\"off\"" || x_4[0].goType == 'string') {
                return ({ goType: 'string', gostuff: gostuff });
            }
            if (x_4[0].goType == 'TextDocumentSyncOptions') {
                return ({ goType: 'interface{}', gostuff: gostuff });
            }
            if (x_4[0].goType == 'float64' && x_4[1].goType == 'string') {
                return {
                    goType: 'interface{}', gostuff: gostuff
                };
            }
            if (x_4[0].goType == 'MarkupContent' && x_4[1].goType == 'MarkedString') {
                return {
                    goType: 'MarkupContent', gostuff: gostuff
                };
            }
            // Fail loudly
            console.log("UnionType " + loc(node));
            for (var _i = 0, x_2 = x_4; _i < x_2.length; _i++) {
                var v = x_2[_i];
                console.log("" + v.goType);
            }
            throw new Error('in UnionType, weird');
        }
        else if (ts.isParenthesizedTypeNode(node)) {
            // check that this is (TextDocumentEdit | CreateFile | RenameFile |
            // DeleteFile)
            return {
                goType: 'TextDocumentEdit', gostuff: getText(node)
            };
        }
        else if (ts.isTupleTypeNode(node)) {
            // string | [number, number]
            return {
                goType: 'string', gostuff: getText(node)
            };
        }
        throw new Error("unknown " + ts.SyntaxKind[node.kind] + " at " + loc(node));
    }
    function fromIndexSignature(node) {
        var parm;
        var at;
        node.forEachChild(function (n) {
            if (ts.isParameter(n)) {
                parm = n;
            }
            else if (ts.isArrayTypeNode(n) || n.kind == ts.SyntaxKind.AnyKeyword ||
                ts.isUnionTypeNode(n)) {
                at = n;
            }
            else
                throw new Error("fromIndexSig " + ts.SyntaxKind[n.kind] + " " + loc(n));
        });
        var goType = computeType(at).goType;
        var id;
        parm.forEachChild(function (n) {
            if (ts.isIdentifier(n)) {
                id = n;
            }
            else if (n.kind != ts.SyntaxKind.StringKeyword) {
                throw new Error("fromIndexSig expected string, " + ts.SyntaxKind[n.kind] + " " + loc(n));
            }
        });
        goType = "map[string]" + goType;
        return {
            me: node, goName: toGoName(id.text), id: null, goType: goType,
            optional: false, json: "`json:\"" + id.text + "\"`",
            gostuff: "" + getText(node)
        };
    }
    function toGoName(s) {
        var ans = s;
        if (s.charAt(0) == '_') {
            ans = 'Inner' + s.substring(1);
        }
        else {
            ans = s.substring(0, 1).toUpperCase() + s.substring(1);
        }
        ;
        ans = ans.replace(/Uri$/, 'URI');
        ans = ans.replace(/Id$/, 'ID');
        return ans;
    }
    // find the text of a node
    function getText(node) {
        var sf = node.getSourceFile();
        var start = node.getStart(sf);
        var end = node.getEnd();
        return sf.text.substring(start, end);
    }
    // return a string of the kinds of the immediate descendants
    function kinds(n) {
        var res = 'Seen ' + ts.SyntaxKind[n.kind];
        function f(n) { res += ' ' + ts.SyntaxKind[n.kind]; }
        ;
        ts.forEachChild(n, f);
        return res;
    }
    function describe(node) {
        if (node === undefined) {
            return;
        }
        var indent = '';
        function f(n) {
            seenAdd(kinds(n));
            if (ts.isIdentifier(n)) {
                pra(indent + " " + loc(n) + " " + ts.SyntaxKind[n.kind] + " " + n.text + "\n");
            }
            else if (ts.isPropertySignature(n) || ts.isEnumMember(n)) {
                pra(indent + " " + loc(n) + " " + ts.SyntaxKind[n.kind] + "\n");
            }
            else if (ts.isTypeLiteralNode(n)) {
                var m = n.members;
                pra(indent + " " + loc(n) + " " + ts.SyntaxKind[n.kind] + " " + m.length + "\n");
            }
            else {
                pra(indent + " " + loc(n) + " " + ts.SyntaxKind[n.kind] + "\n");
            }
            ;
            indent += '  ';
            ts.forEachChild(n, f);
            indent = indent.slice(0, indent.length - 2);
        }
        f(node);
    }
    function loc(node) {
        var sf = node.getSourceFile();
        var start = node.getStart();
        var x = sf.getLineAndCharacterOfPosition(start);
        var full = node.getFullStart();
        var y = sf.getLineAndCharacterOfPosition(full);
        var fn = sf.fileName;
        var n = fn.search(/-node./);
        fn = fn.substring(n + 6);
        return fn + " " + (x.line + 1) + ":" + (x.character + 1) + " (" + (y.line + 1) + ":" + (y.character + 1) + ")";
    }
}
function getComments(node) {
    var sf = node.getSourceFile();
    var start = node.getStart(sf, false);
    var starta = node.getStart(sf, true);
    var x = sf.text.substring(starta, start);
    return x;
}
function emitTypes() {
    for (var _i = 0, Types_1 = Types; _i < Types_1.length; _i++) {
        var t = Types_1[_i];
        if (t.goName == 'CodeActionKind')
            continue; // consts better choice
        var stuff = (t.stuff == undefined) ? '' : t.stuff;
        prgo("// " + t.goName + " is a type\n");
        prgo("" + getComments(t.me));
        prgo("type " + t.goName + " " + t.goType + stuff + "\n");
    }
}
function emitStructs() {
    var seenName = new Map();
    for (var _i = 0, Structs_1 = Structs; _i < Structs_1.length; _i++) {
        var str = Structs_1[_i];
        if (str.name == 'InitializeError') {
            // only want the consts
            continue;
        }
        if (seenName[str.name]) {
            continue;
        }
        seenName[str.name] = true;
        prgo(genComments(str.name, getComments(str.me)));
        /* prgo(`// ${str.name} is:\n`)
        prgo(getComments(str.me))*/
        prgo("type " + str.name + " struct {\n");
        for (var _a = 0, _b = str.embeds; _a < _b.length; _a++) {
            var s = _b[_a];
            prgo("\t" + s + "\n");
        }
        if (str.fields != undefined) {
            for (var _c = 0, _d = str.fields; _c < _d.length; _c++) {
                var f = _d[_c];
                prgo(strField(f));
            }
        }
        prgo("}\n");
    }
}
function genComments(name, maybe) {
    if (maybe == '')
        return "\n\t// " + name + " is\n";
    if (maybe.indexOf('/**') == 0) {
        return maybe.replace('/**', "\n/*" + name + " defined:");
    }
    throw new Error("weird comment " + maybe.indexOf('/**'));
}
// Turn a Field into an output string
function strField(f) {
    var ans = [];
    var opt = f.optional ? '*' : '';
    switch (f.goType.charAt(0)) {
        case 's': // string
        case 'b': // bool
        case 'f': // float64
        case 'i': // interface{}
        case '[': // []foo
            opt = '';
    }
    var stuff = (f.gostuff == undefined) ? '' : " // " + f.gostuff;
    ans.push(genComments(f.goName, getComments(f.me)));
    if (f.substruct == undefined) {
        ans.push("\t" + f.goName + " " + opt + f.goType + " " + f.json + stuff + "\n");
    }
    else {
        ans.push("\t" + f.goName + " " + opt + "struct {\n");
        for (var _i = 0, _a = f.substruct; _i < _a.length; _i++) {
            var x = _a[_i];
            ans.push(strField(x));
        }
        ans.push("\t} " + f.json + stuff + "\n");
    }
    return (''.concat.apply('', ans));
}
function emitConsts() {
    // Generate modifying prefixes and suffixes to ensure consts are
    // unique. (Go consts are package-level, but Typescript's are not.)
    // Use suffixes to minimize changes to gopls.
    var pref = new Map([['DiagnosticSeverity', 'Severity']]); // typeName->prefix
    var suff = new Map([
        ['CompletionItemKind', 'Completion'], ['InsertTextFormat', 'TextFormat']
    ]);
    for (var _i = 0, Consts_1 = Consts; _i < Consts_1.length; _i++) {
        var c = Consts_1[_i];
        if (seenConstTypes[c.typeName]) {
            continue;
        }
        seenConstTypes[c.typeName] = true;
        if (pref.get(c.typeName) == undefined) {
            pref.set(c.typeName, ''); // initialize to empty value
        }
        if (suff.get(c.typeName) == undefined) {
            suff.set(c.typeName, '');
        }
        prgo("// " + c.typeName + " defines constants\n");
        prgo("type " + c.typeName + " " + c.goType + "\n");
    }
    prgo('const (\n');
    var seenConsts = new Map(); // to avoid duplicates
    for (var _a = 0, Consts_2 = Consts; _a < Consts_2.length; _a++) {
        var c = Consts_2[_a];
        var x = "" + pref.get(c.typeName) + c.name + suff.get(c.typeName);
        if (seenConsts.get(x)) {
            continue;
        }
        seenConsts.set(x, true);
        prgo(genComments(x, getComments(c.me)));
        prgo("\t" + x + " " + c.typeName + " = " + c.value + "\n");
    }
    prgo(')\n');
}
function emitHeader(files) {
    var lastMod = 0;
    var lastDate;
    for (var _i = 0, files_1 = files; _i < files_1.length; _i++) {
        var f = files_1[_i];
        var st = fs.statSync(f);
        if (st.mtimeMs > lastMod) {
            lastMod = st.mtimeMs;
            lastDate = st.mtime;
        }
    }
    prgo("// Package protocol contains data types for LSP jsonrpcs\n");
    prgo("// generated automatically from vscode-languageserver-node\n  //  version of " + lastDate + "\n");
    prgo('package protocol\n\n');
}
;
// ad hoc argument parsing: [-d dir] [-o outputfile], and order matters
function main() {
    var args = process.argv.slice(2); // effective command line
    if (args.length > 0) {
        var j = 0;
        if (args[j] == '-d') {
            dir = args[j + 1];
            j += 2;
        }
        if (args[j] == '-o') {
            outFname = args[j + 1];
            j += 2;
        }
        if (j != args.length)
            throw new Error("incomprehensible args " + args);
    }
    var files = [];
    for (var i = 0; i < fnames.length; i++) {
        files.push("" + dir + fnames[i]);
    }
    createOutputFiles();
    generate(files, { target: ts.ScriptTarget.ES5, module: ts.ModuleKind.CommonJS });
    emitHeader(files);
    emitStructs();
    emitConsts();
    emitTypes();
}
main();
