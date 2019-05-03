// Package protocol contains data types for LSP jsonrpcs
// generated automatically from vscode-languageserver-node
//  version of Fri May 03 2019 10:46:04 GMT+0300 (East Africa Time)
const std = @import("std");
const json = std.json;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const ImplementationClientCapabilities = struct {
    textDocument: ?TextDocumentImpl,
    pub const TextDocumentImpl = struct {
        implementation: ?Implementation,
        pub const Implementation = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,

            pub fn encode(self: *const Implementation, a: *Allocator) !json.Value {
                var m = json.ObjectMap.init(a);
                if (self.dynamicRegistration) |value| {
                    _ = try m.put("dynamicRegistration", json.Value{ .Bool = value });
                }
                if (self.linkSupport) |value| {
                    _ = try m.put("linkSupport", json.Value{ .Bool = value });
                }
                return json.Value{ .Object = m };
            }
        };
        pub fn encode(self: *const TextDocumentImpl, a: *Allocator) !json.Value {
            var m = json.ObjectMap.init(a);
            if (self.implementation) |*value| {
                _ = try m.put("implementation", try value.encode(a));
            }
            return json.Value{ .Object = m };
        }
    };
    pub fn encode(self: *const ImplementationClientCapabilities, a: *Allocator) !json.Value {
        var m = json.ObjectMap.init(a);
        if (self.textDocument) |*value| {
            _ = try m.put("textDocument", try value.encode(a));
        }
        return json.Value{ .Object = m };
    }
};

pub const ImplementationServerCapabilities = struct {
    implementationProvider: ?bool,

    fn encode(self: *const ImplementationServerCapabilities, a: *Allocator) !json.Value {
        var m = json.ObjectMap.init(a);
        if (self.implementationProvider) |value| {
            _ = try m.put("implementationProvider", json.Value{ .Bool = value });
        }
        return json.Value{ .Object = m };
    }
};

pub const TypeDefinitionClientCapabilities = struct {
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        typeDefinition: ?TypeDefinition,
        pub const TypeDefinition = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
};

pub const TypeDefinitionServerCapabilities = struct {
    typeDefinitionProvider: ?bool,
};

pub const WorkspaceFoldersInitializeParams = struct {
    workspaceFolders: ArrayList(WorkspaceFolder),
};

pub const WorkspaceFoldersClientCapabilities = struct {
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspaceFolders: ?bool,
    };
};

pub const WorkspaceFoldersServerCapabilities = struct {
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspaceFolders: ?WorkspaceFolders,
        pub const WorkspaceFolders = struct {
            supported: ?bool,
            changeNotifications: ?[]const u8,
        };
    };
};

pub const WorkspaceFolder = struct {
    uRI: []const u8,
    name: []const u8,
};

pub const DidChangeWorkspaceFoldersParams = struct {
    event: WorkspaceFoldersChangeEvent,
};

pub const WorkspaceFoldersChangeEvent = struct {
    added: ArrayList(WorkspaceFolder),
    removed: ArrayList(WorkspaceFolder),
};

pub const ConfigurationClientCapabilities = struct {
    workspace: ?Workspace,
    pub const Workspace = struct {
        configuration: ?bool,
    };
};

pub const ConfigurationItem = struct {
    scopeUri: ?[]const u8,
    section: ?[]const u8,
};

pub const ConfigurationParams = struct {
    items: ArrayList(ConfigurationItem),
};

pub const ColorClientCapabilities = struct {
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        colorProvider: ?ColorProvider,
        pub const ColorProvider = struct {
            dynamicRegistration: ?bool,
        };
    };
};

pub const ColorProviderOptions = struct {};

pub const ColorServerCapabilities = struct {
    colorProvider: ?bool,
};

pub const DocumentColorParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const ColorPresentationParams = struct {
    textDocument: TextDocumentIdentifier,
    color: Color,
    range: Range,
};

pub const FoldingRangeClientCapabilities = struct {
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        foldingRange: ?FoldingRange,
        pub const FoldingRange = struct {
            dynamicRegistration: ?bool,
            rangeLimit: ?f64,
            lineFoldingOnly: ?bool,
        };
    };
};

pub const FoldingRangeProviderOptions = struct {};

pub const FoldingRangeServerCapabilities = struct {
    foldingRangeProvider: ?bool,
};

pub const FoldingRange = struct {
    startLine: f64,
    startCharacter: ?f64,
    endLine: f64,
    endCharacter: ?f64,
    kind: ?[]const u8,
};

pub const FoldingRangeParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const DeclarationClientCapabilities = struct {
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        declaration: ?Declaration,
        pub const Declaration = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
};

pub const DeclarationServerCapabilities = struct {
    declarationProvider: ?bool,
};

pub const Registration = struct {
    iD: []const u8,
    method: []const u8,
    registerOptions: ?json.Value,
};

pub const RegistrationParams = struct {
    registrations: ArrayList(Registration),
};

pub const Unregistration = struct {
    iD: []const u8,
    method: []const u8,
};

pub const UnregistrationParams = struct {
    unregisterations: ArrayList(Unregistration),
};

pub const TextDocumentPositionParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
};

pub const WorkspaceClientCapabilities = struct {
    applyEdit: ?bool,
    workspaceEdit: ?WorkspaceEdit,
    pub const WorkspaceEdit = struct {
        documentChanges: ?bool,
        resourceOperations: ?ArrayList(ResourceOperationKind),
        failureHandling: ?FailureHandlingKind,
    };
    didChangeConfiguration: ?DidChangeConfiguration,
    pub const DidChangeConfiguration = struct {
        dynamicRegistration: ?bool,
    };
    didChangeWatchedFiles: ?DidChangeWatchedFiles,
    pub const DidChangeWatchedFiles = struct {
        dynamicRegistration: ?bool,
    };
    symbol: ?Symbol,
    pub const Symbol = struct {
        dynamicRegistration: ?bool,
        symbolKind: ?SymbolKind,
        pub const SymbolKind = struct {
            valueSet: ?ArrayList(SymbolKind),
        };
    };
    executeCommand: ?ExecuteCommand,
    pub const ExecuteCommand = struct {
        dynamicRegistration: ?bool,
    };
};

pub const TextDocumentClientCapabilities = struct {
    synchronization: ?Synchronization,
    pub const Synchronization = struct {
        dynamicRegistration: ?bool,
        willSave: ?bool,
        willSaveWaitUntil: ?bool,
        didSave: ?bool,
    };
    completion: ?Completion,
    pub const Completion = struct {
        dynamicRegistration: ?bool,
        completionItem: ?CompletionItem,
        pub const CompletionItem = struct {
            snippetSupport: ?bool,
            commitCharactersSupport: ?bool,
            documentationFormat: ?ArrayList(MarkupKind),
            deprecatedSupport: ?bool,
            preselectSupport: ?bool,
        };
        completionItemKind: ?CompletionItemKind,
        pub const CompletionItemKind = struct {
            valueSet: ?ArrayList(CompletionItemKind),
        };
        contextSupport: ?bool,
    };
    hover: ?Hover,
    pub const Hover = struct {
        dynamicRegistration: ?bool,
        contentFormat: ?ArrayList(MarkupKind),
    };
    signatureHelp: ?SignatureHelp,
    pub const SignatureHelp = struct {
        dynamicRegistration: ?bool,
        signatureInformation: ?SignatureInformation,
        pub const SignatureInformation = struct {
            documentationFormat: ?ArrayList(MarkupKind),
            parameterInformation: ?ParameterInformation,
            pub const ParameterInformation = struct {
                labelOffsetSupport: ?bool,
            };
        };
    };
    references: ?References,
    pub const References = struct {
        dynamicRegistration: ?bool,
    };
    documentHighlight: ?DocumentHighlight,
    pub const DocumentHighlight = struct {
        dynamicRegistration: ?bool,
    };
    documentSymbol: ?DocumentSymbol,
    pub const DocumentSymbol = struct {
        dynamicRegistration: ?bool,
        symbolKind: ?SymbolKind,
        pub const SymbolKind = struct {
            valueSet: ?ArrayList(SymbolKind),
        };
        hierarchicalDocumentSymbolSupport: ?bool,
    };
    formatting: ?Formatting,
    pub const Formatting = struct {
        dynamicRegistration: ?bool,
    };
    rangeFormatting: ?RangeFormatting,
    pub const RangeFormatting = struct {
        dynamicRegistration: ?bool,
    };
    onTypeFormatting: ?OnTypeFormatting,
    pub const OnTypeFormatting = struct {
        dynamicRegistration: ?bool,
    };
    definition: ?Definition,
    pub const Definition = struct {
        dynamicRegistration: ?bool,
        linkSupport: ?bool,
    };
    codeAction: ?CodeAction,
    pub const CodeAction = struct {
        dynamicRegistration: ?bool,
        codeActionLiteralSupport: ?CodeActionLiteralSupport,
        pub const CodeActionLiteralSupport = struct {
            codeActionKind: CodeActionKind,
            pub const CodeActionKind = struct {
                valueSet: ArrayList(CodeActionKind),
            };
        };
    };
    codeLens: ?CodeLens,
    pub const CodeLens = struct {
        dynamicRegistration: ?bool,
    };
    documentLink: ?DocumentLink,
    pub const DocumentLink = struct {
        dynamicRegistration: ?bool,
    };
    rename: ?Rename,
    pub const Rename = struct {
        dynamicRegistration: ?bool,
        prepareSupport: ?bool,
    };
    publishDiagnostics: ?PublishDiagnostics,
    pub const PublishDiagnostics = struct {
        relatedInformation: ?bool,
        tagSupport: ?bool,
    };
};

pub const WindowClientCapabilities = struct {
    progress: ?bool,
};

pub const InnerClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    textDocument: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
};

pub const ClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    textDocument: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        implementation: ?Implementation,
        pub const Implementation = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        typeDefinition: ?TypeDefinition,
        pub const TypeDefinition = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspaceFolders: ?bool,
    };
    workspace: ?Workspace,
    pub const Workspace = struct {
        configuration: ?bool,
    };
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        colorProvider: ?ColorProvider,
        pub const ColorProvider = struct {
            dynamicRegistration: ?bool,
        };
    };
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        foldingRange: ?FoldingRange,
        pub const FoldingRange = struct {
            dynamicRegistration: ?bool,
            rangeLimit: ?f64,
            lineFoldingOnly: ?bool,
        };
    };
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        declaration: ?Declaration,
        pub const Declaration = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
};

pub const StaticRegistrationOptions = struct {
    iD: ?[]const u8,
};

pub const TextDocumentRegistrationOptions = struct {
    documentSelector: DocumentSelector,
};

pub const CompletionOptions = struct {
    triggerCharacters: ?ArrayList([]const u8),
    allCommitCharacters: ?ArrayList([]const u8),
    resolveProvider: ?bool,
};

pub const SignatureHelpOptions = struct {
    triggerCharacters: ?ArrayList([]const u8),
};

pub const CodeActionOptions = struct {
    codeActionKinds: ?ArrayList(CodeActionKind),
};

pub const CodeLensOptions = struct {
    resolveProvider: ?bool,
};

pub const DocumentOnTypeFormattingOptions = struct {
    firstTriggerCharacter: []const u8,
    moreTriggerCharacter: ?ArrayList([]const u8),
};

pub const RenameOptions = struct {
    prepareProvider: ?bool,
};

pub const DocumentLinkOptions = struct {
    resolveProvider: ?bool,
};

pub const ExecuteCommandOptions = struct {
    commands: ArrayList([]const u8),
};

pub const SaveOptions = struct {
    includeText: ?bool,
};

pub const TextDocumentSyncOptions = struct {
    openClose: ?bool,
    change: TextDocumentSyncKind,
    willSave: ?bool,
    willSaveWaitUntil: ?bool,
    save: ?SaveOptions,
};

pub const InnerServerCapabilities = struct {
    textDocumentSync: ?json.Value,
    hoverProvider: ?bool,
    completionProvider: ?CompletionOptions,
    signatureHelpProvider: ?SignatureHelpOptions,
    definitionProvider: ?bool,
    referencesProvider: ?bool,
    documentHighlightProvider: ?bool,
    documentSymbolProvider: ?bool,
    workspaceSymbolProvider: ?bool,
    codeActionProvider: ?bool,
    codeLensProvider: ?CodeLensOptions,
    documentFormattingProvider: ?bool,
    documentRangeFormattingProvider: ?bool,
    documentOnTypeFormattingProvider: ?DocumentOnTypeFormattingProvider,
    pub const DocumentOnTypeFormattingProvider = struct {
        firstTriggerCharacter: []const u8,
        moreTriggerCharacter: ?ArrayList([]const u8),
    };
    renameProvider: ?bool,
    documentLinkProvider: ?DocumentLinkOptions,
    executeCommandProvider: ?ExecuteCommandOptions,
    experimental: ?json.Value,
};

pub const ServerCapabilities = struct {
    textDocumentSync: ?json.Value,
    hoverProvider: ?bool,
    completionProvider: ?CompletionOptions,
    signatureHelpProvider: ?SignatureHelpOptions,
    definitionProvider: ?bool,
    referencesProvider: ?bool,
    documentHighlightProvider: ?bool,
    documentSymbolProvider: ?bool,
    workspaceSymbolProvider: ?bool,
    codeActionProvider: ?bool,
    codeLensProvider: ?CodeLensOptions,
    documentFormattingProvider: ?bool,
    documentRangeFormattingProvider: ?bool,
    documentOnTypeFormattingProvider: ?DocumentOnTypeFormattingProvider,
    pub const DocumentOnTypeFormattingProvider = struct {
        firstTriggerCharacter: []const u8,
        moreTriggerCharacter: ?ArrayList([]const u8),
    };
    renameProvider: ?bool,
    documentLinkProvider: ?DocumentLinkOptions,
    executeCommandProvider: ?ExecuteCommandOptions,
    experimental: ?json.Value,
    implementationProvider: ?bool,
    typeDefinitionProvider: ?bool,
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspaceFolders: ?WorkspaceFolders,
        pub const WorkspaceFolders = struct {
            supported: ?bool,
            changeNotifications: ?[]const u8,
        };
    };
    colorProvider: ?bool,
    foldingRangeProvider: ?bool,
    declarationProvider: ?bool,
};

pub const InnerInitializeParams = struct {
    processId: f64,
    rootPath: ?[]const u8,
    rootUri: []const u8,
    capabilities: ClientCapabilities,
    initializationOptions: ?json.Value,
    trace: ?[]const u8,
};

pub const InitializeParams = struct {
    processId: f64,
    rootPath: ?[]const u8,
    rootUri: []const u8,
    capabilities: ClientCapabilities,
    initializationOptions: ?json.Value,
    trace: ?[]const u8,
    workspaceFolders: ArrayList(WorkspaceFolder),
};

pub const InitializeResult = struct {
    capabilities: ServerCapabilities,
    custom: json.ObjectMap,
};

pub const InitializedParams = struct {};

pub const DidChangeConfigurationRegistrationOptions = struct {
    section: ?[]const u8,
};

pub const DidChangeConfigurationParams = struct {
    settings: json.Value,
};

pub const ShowMessageParams = struct {
    type: MessageType,
    message: []const u8,
};

pub const MessageActionItem = struct {
    title: []const u8,
};

pub const ShowMessageRequestParams = struct {
    type: MessageType,
    message: []const u8,
    actions: ?ArrayList(MessageActionItem),
};

pub const LogMessageParams = struct {
    type: MessageType,
    message: []const u8,
};

pub const DidOpenTextDocumentParams = struct {
    textDocument: TextDocumentItem,
};

pub const DidChangeTextDocumentParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    contentChanges: ArrayList(TextDocumentContentChangeEvent),
};

pub const TextDocumentChangeRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    syncKind: TextDocumentSyncKind,
};

pub const DidCloseTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const DidSaveTextDocumentParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    text: ?[]const u8,
};

pub const TextDocumentSaveRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    includeText: ?bool,
};

pub const WillSaveTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
    reason: TextDocumentSaveReason,
};

pub const DidChangeWatchedFilesParams = struct {
    changes: ArrayList(FileEvent),
};

pub const FileEvent = struct {
    uRI: []const u8,
    type: FileChangeType,
};

pub const DidChangeWatchedFilesRegistrationOptions = struct {
    watchers: ArrayList(FileSystemWatcher),
};

pub const FileSystemWatcher = struct {
    globPattern: []const u8,
    kind: ?f64,
};

pub const PublishDiagnosticsParams = struct {
    uRI: []const u8,
    version: ?f64,
    diagnostics: ArrayList(Diagnostic),
};

pub const CompletionRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    triggerCharacters: ?ArrayList([]const u8),
    allCommitCharacters: ?ArrayList([]const u8),
    resolveProvider: ?bool,
};

pub const CompletionContext = struct {
    triggerKind: CompletionTriggerKind,
    triggerCharacter: ?[]const u8,
};

pub const CompletionParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    context: ?CompletionContext,
};

pub const SignatureHelpRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    triggerCharacters: ?ArrayList([]const u8),
};

pub const ReferenceParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    context: ReferenceContext,
};

pub const CodeActionParams = struct {
    textDocument: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};

pub const CodeActionRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    codeActionKinds: ?ArrayList(CodeActionKind),
};

pub const CodeLensParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const CodeLensRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    resolveProvider: ?bool,
};

pub const DocumentFormattingParams = struct {
    textDocument: TextDocumentIdentifier,
    options: FormattingOptions,
};

pub const DocumentRangeFormattingParams = struct {
    textDocument: TextDocumentIdentifier,
    range: Range,
    options: FormattingOptions,
};

pub const DocumentOnTypeFormattingParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    ch: []const u8,
    options: FormattingOptions,
};

pub const DocumentOnTypeFormattingRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    firstTriggerCharacter: []const u8,
    moreTriggerCharacter: ?ArrayList([]const u8),
};

pub const RenameParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    newName: []const u8,
};

pub const RenameRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    prepareProvider: ?bool,
};

pub const DocumentLinkParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const DocumentLinkRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    resolveProvider: ?bool,
};

pub const ExecuteCommandParams = struct {
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};

pub const ExecuteCommandRegistrationOptions = struct {
    commands: ArrayList([]const u8),
};

pub const ApplyWorkspaceEditParams = struct {
    label: ?[]const u8,
    edit: WorkspaceEdit,
};

pub const ApplyWorkspaceEditResponse = struct {
    applied: bool,
    failureReason: ?[]const u8,
    failedChange: ?f64,
};

pub const Position = struct {
    line: f64,
    character: f64,
};

pub const Range = struct {
    start: Position,
    end: Position,
};

pub const Location = struct {
    uRI: []const u8,
    range: Range,
};

pub const LocationLink = struct {
    originSelectionRange: ?Range,
    targetUri: []const u8,
    targetRange: Range,
    targetSelectionRange: Range,
};

pub const Color = struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

pub const ColorInformation = struct {
    range: Range,
    color: Color,
};

pub const ColorPresentation = struct {
    label: []const u8,
    textEdit: ?TextEdit,
    additionalTextEdits: ?ArrayList(TextEdit),
};

pub const DiagnosticRelatedInformation = struct {
    location: Location,
    message: []const u8,
};

pub const Diagnostic = struct {
    range: Range,
    severity: DiagnosticSeverity,
    code: ?json.Value,
    source: ?[]const u8,
    message: []const u8,
    tags: ?ArrayList(DiagnosticTag),
    relatedInformation: ?ArrayList(DiagnosticRelatedInformation),
};

pub const Command = struct {
    title: []const u8,
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};

pub const TextEdit = struct {
    range: Range,
    newText: []const u8,
};

pub const TextDocumentEdit = struct {
    textDocument: VersionedTextDocumentIdentifier,
    edits: ArrayList(TextEdit),
};

pub const ResourceOperation = struct {
    kind: []const u8,
};

pub const CreateFileOptions = struct {
    overwrite: ?bool,
    ignoreIfExists: ?bool,
};

pub const CreateFile = struct {
    kind: []const u8,
    kind: []const u8,
    uRI: []const u8,
    options: ?CreateFileOptions,
};

pub const RenameFileOptions = struct {
    overwrite: ?bool,
    ignoreIfExists: ?bool,
};

pub const RenameFile = struct {
    kind: []const u8,
    kind: []const u8,
    oldUri: []const u8,
    newUri: []const u8,
    options: ?RenameFileOptions,
};

pub const DeleteFileOptions = struct {
    recursive: ?bool,
    ignoreIfNotExists: ?bool,
};

pub const DeleteFile = struct {
    kind: []const u8,
    kind: []const u8,
    uRI: []const u8,
    options: ?DeleteFileOptions,
};

pub const WorkspaceEdit = struct {
    changes: ?json.ObjectMap,
    documentChanges: ?ArrayList(TextDocumentEdit),
};

pub const TextEditChange = struct {};

pub const TextDocumentIdentifier = struct {
    uRI: []const u8,
};

pub const VersionedTextDocumentIdentifier = struct {
    uRI: []const u8,
    version: f64,
};

pub const TextDocumentItem = struct {
    uRI: []const u8,
    languageId: []const u8,
    version: f64,
    text: []const u8,
};

pub const MarkupContent = struct {
    kind: MarkupKind,
    value: []const u8,
};

pub const CompletionItem = struct {
    label: []const u8,
    kind: CompletionItemKind,
    detail: ?[]const u8,
    documentation: ?[]const u8,
    deprecated: ?bool,
    preselect: ?bool,
    sortText: ?[]const u8,
    filterText: ?[]const u8,
    insertText: ?[]const u8,
    insertTextFormat: InsertTextFormat,
    textEdit: ?TextEdit,
    additionalTextEdits: ?ArrayList(TextEdit),
    commitCharacters: ?ArrayList([]const u8),
    command: ?Command,
    data: ?json.Value,
};

pub const CompletionList = struct {
    isIncomplete: bool,
    items: ArrayList(CompletionItem),
};

pub const Hover = struct {
    contents: MarkupContent,
    range: ?Range,
};

pub const ParameterInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
};

pub const SignatureInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
    parameters: ?ArrayList(ParameterInformation),
};

pub const SignatureHelp = struct {
    signatures: ArrayList(SignatureInformation),
    activeSignature: f64,
    activeParameter: f64,
};

pub const ReferenceContext = struct {
    includeDeclaration: bool,
};

pub const DocumentHighlight = struct {
    range: Range,
    kind: ?DocumentHighlightKind,
};

pub const SymbolInformation = struct {
    name: []const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    location: Location,
    containerName: ?[]const u8,
};

pub const DocumentSymbol = struct {
    name: []const u8,
    detail: ?[]const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    range: Range,
    selectionRange: Range,
    children: ?ArrayList(DocumentSymbol),
};

pub const DocumentSymbolParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const WorkspaceSymbolParams = struct {
    query: []const u8,
};

pub const CodeActionContext = struct {
    diagnostics: ArrayList(Diagnostic),
    only: ?ArrayList(CodeActionKind),
};

pub const CodeAction = struct {
    title: []const u8,
    kind: CodeActionKind,
    diagnostics: ?ArrayList(Diagnostic),
    edit: ?WorkspaceEdit,
    command: ?Command,
};

pub const CodeLens = struct {
    range: Range,
    command: ?Command,
    data: ?json.Value,
};

pub const FormattingOptions = struct {
    tabSize: f64,
    insertSpaces: bool,
    trimTrailingWhitespace: ?bool,
    insertFinalNewline: ?bool,
    trimFinalNewlines: ?bool,
    key: json.ObjectMap,
};

pub const DocumentLink = struct {
    range: Range,
    target: ?[]const u8,
    data: ?json.Value,
};

pub const TextDocument = struct {
    uRI: []const u8,
    languageId: []const u8,
    version: f64,
    lineCount: f64,
};

pub const TextDocumentChangeEvent = struct {
    document: TextDocument,
};

pub const TextDocumentWillSaveEvent = struct {
    document: TextDocument,
    reason: TextDocumentSaveReason,
};

pub const TextDocumentContentChangeEvent = struct {
    range: ?Range,
    rangeLength: ?f64,
    text: []const u8,
};
const FoldingRangeKind = enum {
    Comment,
    Imports,
    Region,
    Comment,
    Imports,
    Region,
    pub fn toString(self: FoldingRangeKind) []const u8 {
        return switch (self) {
            FoldingRangeKind.Comment => "comment",
            FoldingRangeKind.Imports => "imports",
            FoldingRangeKind.Region => "region",
            FoldingRangeKind.Comment => "comment",
            FoldingRangeKind.Imports => "imports",
            FoldingRangeKind.Region => "region",
            else => "",
        };
    }
};
const ResourceOperationKind = enum {
    Create,
    Rename,
    Delete,
    pub fn toString(self: ResourceOperationKind) []const u8 {
        return switch (self) {
            ResourceOperationKind.Create => "create",
            ResourceOperationKind.Rename => "rename",
            ResourceOperationKind.Delete => "delete",
            else => "",
        };
    }
};
const FailureHandlingKind = enum {
    Abort,
    Transactional,
    TextOnlyTransactional,
    Undo,
    pub fn toString(self: FailureHandlingKind) []const u8 {
        return switch (self) {
            FailureHandlingKind.Abort => "abort",
            FailureHandlingKind.Transactional => "transactional",
            FailureHandlingKind.TextOnlyTransactional => "textOnlyTransactional",
            FailureHandlingKind.Undo => "undo",
            else => "",
        };
    }
};
const TextDocumentSyncKind = enum(f64) {
    None = 0,
    Full = 1,
    Incremental = 2,
};
const InitializeError = enum(f64) {
    UnknownProtocolVersion = 1,
};
const MessageType = enum(f64) {
    Error = 1,
    Warning = 2,
    Info = 3,
    Log = 4,
};
const FileChangeType = enum(f64) {
    Created = 1,
    Changed = 2,
    Deleted = 3,
};
const WatchKind = enum(f64) {
    Create = 1,
    Change = 2,
    Delete = 4,
};
const CompletionTriggerKind = enum(f64) {
    Invoked = 1,
    TriggerCharacter = 2,
    TriggerForIncompleteCompletions = 3,
};
const DiagnosticSeverity = enum(f64) {
    Error = 1,
    Warning = 2,
    Information = 3,
    Hint = 4,
};
const DiagnosticTag = enum(f64) {
    Unnecessary = 1,
};
const MarkupKind = enum {
    PlainText,
    Markdown,
    pub fn toString(self: MarkupKind) []const u8 {
        return switch (self) {
            MarkupKind.PlainText => "plaintext",
            MarkupKind.Markdown => "markdown",
            else => "",
        };
    }
};
const CompletionItemKind = enum(f64) {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
};
const InsertTextFormat = enum(f64) {
    PlainText = 1,
    Snippet = 2,
};
const DocumentHighlightKind = enum(f64) {
    Text = 1,
    Read = 2,
    Write = 3,
};
const SymbolKind = enum(f64) {
    File = 1,
    Module = 2,
    Namespace = 3,
    Package = 4,
    Class = 5,
    Method = 6,
    Property = 7,
    Field = 8,
    Constructor = 9,
    Enum = 10,
    Interface = 11,
    Function = 12,
    Variable = 13,
    Constant = 14,
    String = 15,
    Number = 16,
    Boolean = 17,
    Array = 18,
    Object = 19,
    Key = 20,
    Null = 21,
    EnumMember = 22,
    Struct = 23,
    Event = 24,
    Operator = 25,
    TypeParameter = 26,
};
const CodeActionKind = enum {
    QuickFix,
    Refactor,
    RefactorExtract,
    RefactorInline,
    RefactorRewrite,
    Source,
    SourceOrganizeImports,
    pub fn toString(self: CodeActionKind) []const u8 {
        return switch (self) {
            CodeActionKind.QuickFix => "quickfix",
            CodeActionKind.Refactor => "refactor",
            CodeActionKind.RefactorExtract => "refactor.extract",
            CodeActionKind.RefactorInline => "refactor.inline",
            CodeActionKind.RefactorRewrite => "refactor.rewrite",
            CodeActionKind.Source => "source",
            CodeActionKind.SourceOrganizeImports => "source.organizeImports",
            else => "",
        };
    }
};
const TextDocumentSaveReason = enum(f64) {
    Manual = 1,
    AfterDelay = 2,
    FocusOut = 3,
};

// DocumentFilter is a type
const DocumentFilter = struct {
    language: []const u8,
    scheme: ?[]const u8,
    pattern: ?[]const u8,
};

const DocumentSelector = ArrayList(DocumentFilter);

const DefinitionLink = LocationLink;

const DeclarationLink = LocationLink;
