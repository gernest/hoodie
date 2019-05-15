// Package protocol contains data types for LSP jsonrpcs
// generated automatically from vscode-languageserver-node
//  version of Fri May 03 2019 10:46:04 GMT+0300 (East Africa Time)
const std = @import("std");
const json = std.json;
const ArrayList = std.ArrayList;

pub const ImplementationClientCapabilities = struct {
    textDocument: ?TextDocument,
    pub const TextDocument = struct {
        implementation: ?Implementation,
        pub const Implementation = struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        };
    };
};

pub const ImplementationServerCapabilities = struct {
    implementationProvider: ?bool,
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

/// /**
///  * The parameters of a `workspace/didChangeWorkspaceFolders` notification.
///  */
pub const DidChangeWorkspaceFoldersParams = struct {
    event: WorkspaceFoldersChangeEvent,
};

/// /**
///  * The workspace folder change event.
///  */
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

/// /**
///  * The parameters of a configuration request.
///  */
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

/// /**
///  * Parameters for a [DocumentColorRequest](#DocumentColorRequest).
///  */
pub const DocumentColorParams = struct {
    textDocument: TextDocumentIdentifier,
};

/// /**
///  * Parameters for a [ColorPresentationRequest](#ColorPresentationRequest).
///  */
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

/// /**
///  * Represents a folding range.
///  */
pub const FoldingRange = struct {
    startLine: f64,
    startCharacter: ?f64,
    endLine: f64,
    endCharacter: ?f64,
    kind: ?[]const u8,
};

/// /**
///  * Parameters for a [FoldingRangeRequest](#FoldingRangeRequest).
///  */
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

/// /**
///  * General parameters to to register for an notification or to register a provider.
///  */
pub const Registration = struct {
    iD: []const u8,
    method: []const u8,
    registerOptions: ?json.Value,
};

pub const RegistrationParams = struct {
    registrations: ArrayList(Registration),
};

/// /**
///  * General parameters to unregister a request or notification.
///  */
pub const Unregistration = struct {
    iD: []const u8,
    method: []const u8,
};

pub const UnregistrationParams = struct {
    unregisterations: ArrayList(Unregistration),
};

/// /**
///  * A parameter literal used in requests to pass a text document and a position inside that
///  * document.
///  */
pub const TextDocumentPositionParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
};

/// /**
///  * Workspace specific client capabilities.
///  */
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

/// /**
///  * Text document specific client capabilities.
///  */
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

/// /**
///  * Window specific client capabilities.
///  */
pub const WindowClientCapabilities = struct {
    progress: ?bool,
};

/// /**
///  * Defines the capabilities provided by the client.
///  */
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

/// /**
///  * Static registration options to be returned in the initialize
///  * request.
///  */
pub const StaticRegistrationOptions = struct {
    iD: ?[]const u8,
};

/// /**
///  * General text document registration options.
///  */
pub const TextDocumentRegistrationOptions = struct {
    documentSelector: DocumentSelector,
};

/// /**
///  * Completion options.
///  */
pub const CompletionOptions = struct {
    triggerCharacters: ?ArrayList([]const u8),
    allCommitCharacters: ?ArrayList([]const u8),
    resolveProvider: ?bool,
};

/// /**
///  * Signature help options.
///  */
pub const SignatureHelpOptions = struct {
    triggerCharacters: ?ArrayList([]const u8),
};

/// /**
///  * Code Action options.
///  */
pub const CodeActionOptions = struct {
    codeActionKinds: ?ArrayList(CodeActionKind),
};

/// /**
///  * Code Lens options.
///  */
pub const CodeLensOptions = struct {
    resolveProvider: ?bool,
};

/// /**
///  * Format document on type options
///  */
pub const DocumentOnTypeFormattingOptions = struct {
    firstTriggerCharacter: []const u8,
    moreTriggerCharacter: ?ArrayList([]const u8),
};

/// /**
///  * Rename options
///  */
pub const RenameOptions = struct {
    prepareProvider: ?bool,
};

/// /**
///  * Document link options
///  */
pub const DocumentLinkOptions = struct {
    resolveProvider: ?bool,
};

/// /**
///  * Execute command options.
///  */
pub const ExecuteCommandOptions = struct {
    commands: ArrayList([]const u8),
};

/// /**
///  * Save options.
///  */
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

/// /**
///  * Defines the capabilities provided by a language
///  * server.
///  */
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

/// /**
///  * The initialize parameters
///  */
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

/// /**
///  * The result returned from an initialize request.
///  */
pub const InitializeResult = struct {
    capabilities: ServerCapabilities,
    custom: json.ObjectMap,
};

pub const InitializedParams = struct {};

pub const DidChangeConfigurationRegistrationOptions = struct {
    section: ?[]const u8,
};

/// /**
///  * The parameters of a change configuration notification.
///  */
pub const DidChangeConfigurationParams = struct {
    settings: json.Value,
};

/// /**
///  * The parameters of a notification message.
///  */
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

/// /**
///  * The log message parameters.
///  */
pub const LogMessageParams = struct {
    type: MessageType,
    message: []const u8,
};

/// /**
///  * The parameters send in a open text document notification
///  */
pub const DidOpenTextDocumentParams = struct {
    textDocument: TextDocumentItem,
};

/// /**
///  * The change text document notification's parameters.
///  */
pub const DidChangeTextDocumentParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    contentChanges: ArrayList(TextDocumentContentChangeEvent),
};

/// /**
///  * Describe options to be used when registered for text document change events.
///  */
pub const TextDocumentChangeRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    syncKind: TextDocumentSyncKind,
};

/// /**
///  * The parameters send in a close text document notification
///  */
pub const DidCloseTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
};

/// /**
///  * The parameters send in a save text document notification
///  */
pub const DidSaveTextDocumentParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    text: ?[]const u8,
};

/// /**
///  * Save registration options.
///  */
pub const TextDocumentSaveRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    includeText: ?bool,
};

/// /**
///  * The parameters send in a will save text document notification.
///  */
pub const WillSaveTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
    reason: TextDocumentSaveReason,
};

/// /**
///  * The watched files change notification's parameters.
///  */
pub const DidChangeWatchedFilesParams = struct {
    changes: ArrayList(FileEvent),
};

/// /**
///  * An event describing a file change.
///  */
pub const FileEvent = struct {
    uRI: []const u8,
    type: FileChangeType,
};

/// /**
///  * Describe options to be used when registered for text document change events.
///  */
pub const DidChangeWatchedFilesRegistrationOptions = struct {
    watchers: ArrayList(FileSystemWatcher),
};

pub const FileSystemWatcher = struct {
    globPattern: []const u8,
    kind: ?f64,
};

/// /**
///  * The publish diagnostic notification's parameters.
///  */
pub const PublishDiagnosticsParams = struct {
    uRI: []const u8,
    version: ?f64,
    diagnostics: ArrayList(Diagnostic),
};

/// /**
///  * Completion registration options.
///  */
pub const CompletionRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    triggerCharacters: ?ArrayList([]const u8),
    allCommitCharacters: ?ArrayList([]const u8),
    resolveProvider: ?bool,
};

/// /**
///  * Contains additional information about the context in which a completion request is triggered.
///  */
pub const CompletionContext = struct {
    triggerKind: CompletionTriggerKind,
    triggerCharacter: ?[]const u8,
};

/// /**
///  * Completion parameters
///  */
pub const CompletionParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    context: ?CompletionContext,
};

/// /**
///  * Signature help registration options.
///  */
pub const SignatureHelpRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    triggerCharacters: ?ArrayList([]const u8),
};

/// /**
///  * Parameters for a [ReferencesRequest](#ReferencesRequest).
///  */
pub const ReferenceParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    context: ReferenceContext,
};

/// /**
///  * Params for the CodeActionRequest
///  */
pub const CodeActionParams = struct {
    textDocument: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};

pub const CodeActionRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    codeActionKinds: ?ArrayList(CodeActionKind),
};

/// /**
///  * Params for the Code Lens request.
///  */
pub const CodeLensParams = struct {
    textDocument: TextDocumentIdentifier,
};

/// /**
///  * Code Lens registration options.
///  */
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

/// /**
///  * Format document on type options
///  */
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

/// /**
///  * Rename registration options.
///  */
pub const RenameRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    prepareProvider: ?bool,
};

pub const DocumentLinkParams = struct {
    textDocument: TextDocumentIdentifier,
};

/// /**
///  * Document link registration options
///  */
pub const DocumentLinkRegistrationOptions = struct {
    documentSelector: DocumentSelector,
    resolveProvider: ?bool,
};

pub const ExecuteCommandParams = struct {
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};

/// /**
///  * Execute command registration options.
///  */
pub const ExecuteCommandRegistrationOptions = struct {
    commands: ArrayList([]const u8),
};

/// /**
///  * The parameters passed via a apply workspace edit request.
///  */
pub const ApplyWorkspaceEditParams = struct {
    label: ?[]const u8,
    edit: WorkspaceEdit,
};

/// /**
///  * A response returned from the apply workspace edit request.
///  */
pub const ApplyWorkspaceEditResponse = struct {
    applied: bool,
    failureReason: ?[]const u8,
    failedChange: ?f64,
};

/// /**
///  * Position in a text document expressed as zero-based line and character offset.
///  * The offsets are based on a UTF-16 string representation. So a string of the form
///  * `a𐐀b` the character offset of the character `a` is 0, the character offset of `𐐀`
///  * is 1 and the character offset of b is 3 since `𐐀` is represented using two code
///  * units in UTF-16.
///  *
///  * Positions are line end character agnostic. So you can not specify a position that
///  * denotes `\r|\n` or `\n|` where `|` represents the character offset.
///  */
pub const Position = struct {
    line: f64,
    character: f64,
};

/// /**
///  * A range in a text document expressed as (zero-based) start and end positions.
///  *
///  * If you want to specify a range that contains a line including the line ending
///  * character(s) then use an end position denoting the start of the next line.
///  * For example:
///  * ```ts
///  * {
///  *     start: { line: 5, character: 23 }
///  *     end : { line 6, character : 0 }
///  * }
///  * ```
///  */
pub const Range = struct {
    start: Position,
    end: Position,
};

/// /**
///  * Represents a location inside a resource, such as a line
///  * inside a text file.
///  */
pub const Location = struct {
    uRI: []const u8,
    range: Range,
};

/// /**
///    * Represents the connection of two locations. Provides additional metadata over normal [locations](#Location),
///    * including an origin range.
///  */
pub const LocationLink = struct {
    originSelectionRange: ?Range,
    targetUri: []const u8,
    targetRange: Range,
    targetSelectionRange: Range,
};

/// /**
///  * Represents a color in RGBA space.
///  */
pub const Color = struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

/// /**
///  * Represents a color range from a document.
///  */
pub const ColorInformation = struct {
    range: Range,
    color: Color,
};

pub const ColorPresentation = struct {
    label: []const u8,
    textEdit: ?TextEdit,
    additionalTextEdits: ?ArrayList(TextEdit),
};

/// /**
///  * Represents a related message and source code location for a diagnostic. This should be
///  * used to point to code locations that cause or related to a diagnostics, e.g when duplicating
///  * a symbol in a scope.
///  */
pub const DiagnosticRelatedInformation = struct {
    location: Location,
    message: []const u8,
};

/// /**
///  * Represents a diagnostic, such as a compiler error or warning. Diagnostic objects
///  * are only valid in the scope of a resource.
///  */
pub const Diagnostic = struct {
    range: Range,
    severity: DiagnosticSeverity,
    code: ?json.Value,
    source: ?[]const u8,
    message: []const u8,
    tags: ?ArrayList(DiagnosticTag),
    relatedInformation: ?ArrayList(DiagnosticRelatedInformation),
};

/// /**
///  * Represents a reference to a command. Provides a title which
///  * will be used to represent a command in the UI and, optionally,
///  * an array of arguments which will be passed to the command handler
///  * function when invoked.
///  */
pub const Command = struct {
    title: []const u8,
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};

/// /**
///  * A text edit applicable to a text document.
///  */
pub const TextEdit = struct {
    range: Range,
    newText: []const u8,
};

/// /**
///  * Describes textual changes on a text document.
///  */
pub const TextDocumentEdit = struct {
    textDocument: VersionedTextDocumentIdentifier,
    edits: ArrayList(TextEdit),
};

pub const ResourceOperation = struct {
    kind: []const u8,
};

/// /**
///  * Options to create a file.
///  */
pub const CreateFileOptions = struct {
    overwrite: ?bool,
    ignoreIfExists: ?bool,
};

/// /**
///  * Create file operation.
///  */
pub const CreateFile = struct {
    kind: []const u8,
    kind: []const u8,
    uRI: []const u8,
    options: ?CreateFileOptions,
};

/// /**
///  * Rename file options
///  */
pub const RenameFileOptions = struct {
    overwrite: ?bool,
    ignoreIfExists: ?bool,
};

/// /**
///  * Rename file operation
///  */
pub const RenameFile = struct {
    kind: []const u8,
    kind: []const u8,
    oldUri: []const u8,
    newUri: []const u8,
    options: ?RenameFileOptions,
};

/// /**
///  * Delete file options
///  */
pub const DeleteFileOptions = struct {
    recursive: ?bool,
    ignoreIfNotExists: ?bool,
};

/// /**
///  * Delete file operation
///  */
pub const DeleteFile = struct {
    kind: []const u8,
    kind: []const u8,
    uRI: []const u8,
    options: ?DeleteFileOptions,
};

/// /**
///  * A workspace edit represents changes to many resources managed in the workspace. The edit
///  * should either provide `changes` or `documentChanges`. If documentChanges are present
///  * they are preferred over `changes` if the client can handle versioned document edits.
///  */
pub const WorkspaceEdit = struct {
    changes: ?json.ObjectMap,
    documentChanges: ?ArrayList(TextDocumentEdit),
};

/// /**
///  * A change to capture text edits for existing resources.
///  */
pub const TextEditChange = struct {};

/// /**
///  * A literal to identify a text document in the client.
///  */
pub const TextDocumentIdentifier = struct {
    uRI: []const u8,
};

/// /**
///  * An identifier to denote a specific version of a text document.
///  */
pub const VersionedTextDocumentIdentifier = struct {
    uRI: []const u8,
    version: f64,
};

/// /**
///  * An item to transfer a text document from the client to the
///  * server.
///  */
pub const TextDocumentItem = struct {
    uRI: []const u8,
    languageId: []const u8,
    version: f64,
    text: []const u8,
};

/// /**
///  * A `MarkupContent` literal represents a string value which content is interpreted base on its
///  * kind flag. Currently the protocol supports `plaintext` and `markdown` as markup kinds.
///  *
///  * If the kind is `markdown` then the value can contain fenced code blocks like in GitHub issues.
///  * See https://help.github.com/articles/creating-and-highlighting-code-blocks/#syntax-highlighting
///  *
///  * Here is an example how such a string can be constructed using JavaScript / TypeScript:
///  * ```ts
///  * let markdown: MarkdownContent = {
///  *  kind: MarkupKind.Markdown,
///  *  value: [
///  *    '# Header',
///  *    'Some text',
///  *    '```typescript',
///  *    'someCode();',
///  *    '```'
///  *  ].join('\n')
///  * };
///  * ```
///  *
///  * *Please Note* that clients might sanitize the return markdown. A client could decide to
///  * remove HTML from the markdown to avoid script execution.
///  */
pub const MarkupContent = struct {
    kind: MarkupKind,
    value: []const u8,
};

/// /**
///  * A completion item represents a text snippet that is
///  * proposed to complete text that is being typed.
///  */
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

/// /**
///  * Represents a collection of [completion items](#CompletionItem) to be presented
///  * in the editor.
///  */
pub const CompletionList = struct {
    isIncomplete: bool,
    items: ArrayList(CompletionItem),
};

/// /**
///  * The result of a hover request.
///  */
pub const Hover = struct {
    contents: MarkupContent,
    range: ?Range,
};

/// /**
///  * Represents a parameter of a callable-signature. A parameter can
///  * have a label and a doc-comment.
///  */
pub const ParameterInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
};

/// /**
///  * Represents the signature of something callable. A signature
///  * can have a label, like a function-name, a doc-comment, and
///  * a set of parameters.
///  */
pub const SignatureInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
    parameters: ?ArrayList(ParameterInformation),
};

/// /**
///  * Signature help represents the signature of something
///  * callable. There can be multiple signature but only one
///  * active and only one active parameter.
///  */
pub const SignatureHelp = struct {
    signatures: ArrayList(SignatureInformation),
    activeSignature: f64,
    activeParameter: f64,
};

/// /**
///  * Value-object that contains additional information when
///  * requesting references.
///  */
pub const ReferenceContext = struct {
    includeDeclaration: bool,
};

/// /**
///  * A document highlight is a range inside a text document which deserves
///  * special attention. Usually a document highlight is visualized by changing
///  * the background color of its range.
///  */
pub const DocumentHighlight = struct {
    range: Range,
    kind: ?DocumentHighlightKind,
};

/// /**
///  * Represents information about programming constructs like variables, classes,
///  * interfaces etc.
///  */
pub const SymbolInformation = struct {
    name: []const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    location: Location,
    containerName: ?[]const u8,
};

/// /**
///  * Represents programming constructs like variables, classes, interfaces etc.
///  * that appear in a document. Document symbols can be hierarchical and they
///  * have two ranges: one that encloses its definition and one that points to
///  * its most interesting range, e.g. the range of an identifier.
///  */
pub const DocumentSymbol = struct {
    name: []const u8,
    detail: ?[]const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    range: Range,
    selectionRange: Range,
    children: ?ArrayList(DocumentSymbol),
};

/// /**
///  * Parameters for a [DocumentSymbolRequest](#DocumentSymbolRequest).
///  */
pub const DocumentSymbolParams = struct {
    textDocument: TextDocumentIdentifier,
};

/// /**
///  * The parameters of a [WorkspaceSymbolRequest](#WorkspaceSymbolRequest).
///  */
pub const WorkspaceSymbolParams = struct {
    query: []const u8,
};

/// /**
///  * Contains additional diagnostic information about the context in which
///  * a [code action](#CodeActionProvider.provideCodeActions) is run.
///  */
pub const CodeActionContext = struct {
    diagnostics: ArrayList(Diagnostic),
    only: ?ArrayList(CodeActionKind),
};

/// /**
///  * A code action represents a change that can be performed in code, e.g. to fix a problem or
///  * to refactor code.
///  *
///  * A CodeAction must set either `edit` and/or a `command`. If both are supplied, the `edit` is applied first, then the `command` is executed.
///  */
pub const CodeAction = struct {
    title: []const u8,
    kind: CodeActionKind,
    diagnostics: ?ArrayList(Diagnostic),
    edit: ?WorkspaceEdit,
    command: ?Command,
};

/// /**
///  * A code lens represents a [command](#Command) that should be shown along with
///  * source text, like the number of references, a way to run tests, etc.
///  *
///  * A code lens is _unresolved_ when no command is associated to it. For performance
///  * reasons the creation of a code lens and resolving should be done to two stages.
///  */
pub const CodeLens = struct {
    range: Range,
    command: ?Command,
    data: ?json.Value,
};

/// /**
///  * Value-object describing what options formatting should use.
///  */
pub const FormattingOptions = struct {
    tabSize: f64,
    insertSpaces: bool,
    trimTrailingWhitespace: ?bool,
    insertFinalNewline: ?bool,
    trimFinalNewlines: ?bool,
    key: json.ObjectMap,
};

/// /**
///  * A document link is a range in a text document that links to an internal or external resource, like another
///  * text document or a web site.
///  */
pub const DocumentLink = struct {
    range: Range,
    target: ?[]const u8,
    data: ?json.Value,
};

/// /**
///  * A simple text document. Not to be implemented.
///  */
pub const TextDocument = struct {
    uRI: []const u8,
    languageId: []const u8,
    version: f64,
    lineCount: f64,
};

/// /**
///  * Event to signal changes to a simple text document.
///  */
pub const TextDocumentChangeEvent = struct {
    document: TextDocument,
};

pub const TextDocumentWillSaveEvent = struct {
    document: TextDocument,
    reason: TextDocumentSaveReason,
};

/// /**
///  * An event describing a change to a text document. If range and rangeLength are omitted
///  * the new text is considered to be the full content of the document.
///  */
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
