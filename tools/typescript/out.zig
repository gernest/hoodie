// Package protocol contains data types for LSP jsonrpcs
// generated automatically from vscode-languageserver-node
//  version of Tue Apr 23 2019 15:01:15 GMT+0300 (East Africa Time)
const ImplementationClientCapabilities = struct {
    text_document: *TextDocument,
    const TextDocument = struct {
        implementation: *Implementation,
        const Implementation = struct {
            dynamic_registration: bool,
            link_support: bool,
        };
    };
};
const ImplementationServerCapabilities = struct {
    implementation_provider: bool,
};
const TypeDefinitionClientCapabilities = struct {
    text_document: *TextDocument,
    const TextDocument = struct {
        type_definition: *TypeDefinition,
        const TypeDefinition = struct {
            dynamic_registration: bool,
            link_support: bool,
        };
    };
};
const TypeDefinitionServerCapabilities = struct {
    type_definition_provider: bool,
};
const WorkspaceFoldersInitializeParams = struct {};
const WorkspaceFoldersClientCapabilities = struct {
    workspace: *Workspace,
    const Workspace = struct {
        workspace_folders: bool,
    };
};
const WorkspaceFoldersServerCapabilities = struct {
    workspace: *Workspace,
    const Workspace = struct {
        workspace_folders: *WorkspaceFolders,
        const WorkspaceFolders = struct {
            supported: bool,
            change_notifications: string,
        };
    };
};
const WorkspaceFolder = struct {
    uri: string,
    name: string,
};
const DidChangeWorkspaceFoldersParams = struct {
    event: WorkspaceFoldersChangeEvent,
};
const WorkspaceFoldersChangeEvent = struct {};
const ConfigurationClientCapabilities = struct {
    workspace: *Workspace,
    const Workspace = struct {
        configuration: bool,
    };
};
const ConfigurationItem = struct {
    scope_uri: string,
    section: string,
};
const ConfigurationParams = struct {};
const ColorClientCapabilities = struct {
    text_document: *TextDocument,
    const TextDocument = struct {
        color_provider: *ColorProvider,
        const ColorProvider = struct {
            dynamic_registration: bool,
        };
    };
};
const ColorProviderOptions = struct {};
const ColorServerCapabilities = struct {
    color_provider: bool,
};
const DocumentColorParams = struct {
    text_document: TextDocumentIdentifier,
};
const ColorPresentationParams = struct {
    text_document: TextDocumentIdentifier,
    color: Color,
    range: Range,
};
const FoldingRangeClientCapabilities = struct {
    text_document: *TextDocument,
    const TextDocument = struct {
        folding_range: *FoldingRange,
        const FoldingRange = struct {
            dynamic_registration: bool,
            range_limit: float64,
            line_folding_only: bool,
        };
    };
};
const FoldingRangeProviderOptions = struct {};
const FoldingRangeServerCapabilities = struct {
    folding_range_provider: bool,
};
const FoldingRange = struct {
    start_line: float64,
    start_character: float64,
    end_line: float64,
    end_character: float64,
    kind: string,
};
const FoldingRangeParams = struct {
    text_document: TextDocumentIdentifier,
};
const DeclarationClientCapabilities = struct {
    text_document: *TextDocument,
    const TextDocument = struct {
        declaration: *Declaration,
        const Declaration = struct {
            dynamic_registration: bool,
            link_support: bool,
        };
    };
};
const DeclarationServerCapabilities = struct {
    declaration_provider: bool,
};
const Registration = struct {
    id: string,
    method: string,
};
const RegistrationParams = struct {};
const Unregistration = struct {
    id: string,
    method: string,
};
const UnregistrationParams = struct {};
const TextDocumentPositionParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
};
const WorkspaceClientCapabilities = struct {
    apply_edit: bool,
    workspace_edit: *WorkspaceEdit,
    const WorkspaceEdit = struct {
        document_changes: bool,
        failure_handling: *FailureHandlingKind,
    };
    did_change_configuration: *DidChangeConfiguration,
    const DidChangeConfiguration = struct {
        dynamic_registration: bool,
    };
    did_change_watched_files: *DidChangeWatchedFiles,
    const DidChangeWatchedFiles = struct {
        dynamic_registration: bool,
    };
    symbol: *Symbol,
    const Symbol = struct {
        dynamic_registration: bool,
        symbol_kind: *SymbolKind,
        const SymbolKind = struct {};
    };
    execute_command: *ExecuteCommand,
    const ExecuteCommand = struct {
        dynamic_registration: bool,
    };
};
const TextDocumentClientCapabilities = struct {
    synchronization: *Synchronization,
    const Synchronization = struct {
        dynamic_registration: bool,
        will_save: bool,
        will_save_wait_until: bool,
        did_save: bool,
    };
    completion: *Completion,
    const Completion = struct {
        dynamic_registration: bool,
        completion_item: *CompletionItem,
        const CompletionItem = struct {
            snippet_support: bool,
            commit_characters_support: bool,
            deprecated_support: bool,
            preselect_support: bool,
        };
        completion_item_kind: *CompletionItemKind,
        const CompletionItemKind = struct {};
        context_support: bool,
    };
    hover: *Hover,
    const Hover = struct {
        dynamic_registration: bool,
    };
    signature_help: *SignatureHelp,
    const SignatureHelp = struct {
        dynamic_registration: bool,
        signature_information: *SignatureInformation,
        const SignatureInformation = struct {
            parameter_information: *ParameterInformation,
            const ParameterInformation = struct {
                label_offset_support: bool,
            };
        };
    };
    references: *References,
    const References = struct {
        dynamic_registration: bool,
    };
    document_highlight: *DocumentHighlight,
    const DocumentHighlight = struct {
        dynamic_registration: bool,
    };
    document_symbol: *DocumentSymbol,
    const DocumentSymbol = struct {
        dynamic_registration: bool,
        symbol_kind: *SymbolKind,
        const SymbolKind = struct {};
        hierarchical_document_symbol_support: bool,
    };
    formatting: *Formatting,
    const Formatting = struct {
        dynamic_registration: bool,
    };
    range_formatting: *RangeFormatting,
    const RangeFormatting = struct {
        dynamic_registration: bool,
    };
    on_type_formatting: *OnTypeFormatting,
    const OnTypeFormatting = struct {
        dynamic_registration: bool,
    };
    definition: *Definition,
    const Definition = struct {
        dynamic_registration: bool,
        link_support: bool,
    };
    code_action: *CodeAction,
    const CodeAction = struct {
        dynamic_registration: bool,
        code_action_literal_support: *CodeActionLiteralSupport,
        const CodeActionLiteralSupport = struct {
            code_action_kind: CodeActionKind,
            const CodeActionKind = struct {};
        };
    };
    code_lens: *CodeLens,
    const CodeLens = struct {
        dynamic_registration: bool,
    };
    document_link: *DocumentLink,
    const DocumentLink = struct {
        dynamic_registration: bool,
    };
    rename: *Rename,
    const Rename = struct {
        dynamic_registration: bool,
        prepare_support: bool,
    };
    publish_diagnostics: *PublishDiagnostics,
    const PublishDiagnostics = struct {
        related_information: bool,
        tag_support: bool,
    };
};
const WindowClientCapabilities = struct {
    progress: bool,
};
const InnerClientCapabilities = struct {
    workspace: *WorkspaceClientCapabilities,
    text_document: *TextDocumentClientCapabilities,
    window: *WindowClientCapabilities,
};
const ClientCapabilities = struct {};
const StaticRegistrationOptions = struct {
    id: string,
};
const TextDocumentRegistrationOptions = struct {
    document_selector: DocumentSelector,
};
const CompletionOptions = struct {
    resolve_provider: bool,
};
const SignatureHelpOptions = struct {};
const CodeActionOptions = struct {};
const CodeLensOptions = struct {
    resolve_provider: bool,
};
const DocumentOnTypeFormattingOptions = struct {
    first_trigger_character: string,
};
const RenameOptions = struct {
    prepare_provider: bool,
};
const DocumentLinkOptions = struct {
    resolve_provider: bool,
};
const ExecuteCommandOptions = struct {};
const SaveOptions = struct {
    include_text: bool,
};
const TextDocumentSyncOptions = struct {
    open_close: bool,
    change: TextDocumentSyncKind,
    will_save: bool,
    will_save_wait_until: bool,
    save: *SaveOptions,
};
const InnerServerCapabilities = struct {
    hover_provider: bool,
    completion_provider: *CompletionOptions,
    signature_help_provider: *SignatureHelpOptions,
    definition_provider: bool,
    references_provider: bool,
    document_highlight_provider: bool,
    document_symbol_provider: bool,
    workspace_symbol_provider: bool,
    code_action_provider: bool,
    code_lens_provider: *CodeLensOptions,
    document_formatting_provider: bool,
    document_range_formatting_provider: bool,
    document_on_type_formatting_provider: *DocumentOnTypeFormattingProvider,
    const DocumentOnTypeFormattingProvider = struct {
        first_trigger_character: string,
    };
    rename_provider: bool,
    document_link_provider: *DocumentLinkOptions,
    execute_command_provider: *ExecuteCommandOptions,
};
const ServerCapabilities = struct {};
const InnerInitializeParams = struct {
    process_id: float64,
    root_path: string,
    root_uri: string,
    capabilities: ClientCapabilities,
    trace: string,
};
const InitializeParams = struct {};
const InitializeResult = struct {
    capabilities: ServerCapabilities,
};
const InitializedParams = struct {};
const DidChangeConfigurationRegistrationOptions = struct {
    section: string,
};
const DidChangeConfigurationParams = struct {};
const ShowMessageParams = struct {
    type: MessageType,
    message: string,
};
const MessageActionItem = struct {
    title: string,
};
const ShowMessageRequestParams = struct {
    type: MessageType,
    message: string,
};
const LogMessageParams = struct {
    type: MessageType,
    message: string,
};
const DidOpenTextDocumentParams = struct {
    text_document: TextDocumentItem,
};
const DidChangeTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
};
const TextDocumentChangeRegistrationOptions = struct {
    sync_kind: TextDocumentSyncKind,
};
const DidCloseTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
};
const DidSaveTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
    text: string,
};
const TextDocumentSaveRegistrationOptions = struct {};
const WillSaveTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
    reason: TextDocumentSaveReason,
};
const DidChangeWatchedFilesParams = struct {};
const FileEvent = struct {
    uri: string,
    type: FileChangeType,
};
const DidChangeWatchedFilesRegistrationOptions = struct {};
const FileSystemWatcher = struct {
    glob_pattern: string,
    kind: float64,
};
const PublishDiagnosticsParams = struct {
    uri: string,
    version: float64,
};
const CompletionRegistrationOptions = struct {};
const CompletionContext = struct {
    trigger_kind: CompletionTriggerKind,
    trigger_character: string,
};
const CompletionParams = struct {
    context: *CompletionContext,
};
const SignatureHelpRegistrationOptions = struct {};
const ReferenceParams = struct {
    context: ReferenceContext,
};
const CodeActionParams = struct {
    text_document: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};
const CodeActionRegistrationOptions = struct {};
const CodeLensParams = struct {
    text_document: TextDocumentIdentifier,
};
const CodeLensRegistrationOptions = struct {};
const DocumentFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    options: FormattingOptions,
};
const DocumentRangeFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    range: Range,
    options: FormattingOptions,
};
const DocumentOnTypeFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    ch: string,
    options: FormattingOptions,
};
const DocumentOnTypeFormattingRegistrationOptions = struct {};
const RenameParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    new_name: string,
};
const RenameRegistrationOptions = struct {};
const DocumentLinkParams = struct {
    text_document: TextDocumentIdentifier,
};
const DocumentLinkRegistrationOptions = struct {};
const ExecuteCommandParams = struct {
    command: string,
};
const ExecuteCommandRegistrationOptions = struct {};
const ApplyWorkspaceEditParams = struct {
    label: string,
    edit: WorkspaceEdit,
};
const ApplyWorkspaceEditResponse = struct {
    applied: bool,
    failure_reason: string,
    failed_change: float64,
};
const Position = struct {
    line: float64,
    character: float64,
};
const Range = struct {
    start: Position,
    end: Position,
};
const Location = struct {
    uri: string,
    range: Range,
};
const LocationLink = struct {
    origin_selection_range: *Range,
    target_uri: string,
    target_range: Range,
    target_selection_range: Range,
};
const Color = struct {
    red: float64,
    green: float64,
    blue: float64,
    alpha: float64,
};
const ColorInformation = struct {
    range: Range,
    color: Color,
};
const ColorPresentation = struct {
    label: string,
    text_edit: *TextEdit,
};
const DiagnosticRelatedInformation = struct {
    location: Location,
    message: string,
};
const Diagnostic = struct {
    range: Range,
    severity: DiagnosticSeverity,
    source: string,
    message: string,
};
const Command = struct {
    title: string,
    command: string,
};
const TextEdit = struct {
    range: Range,
    new_text: string,
};
const TextDocumentEdit = struct {
    text_document: VersionedTextDocumentIdentifier,
};
const ResourceOperation = struct {
    kind: string,
};
const CreateFileOptions = struct {
    overwrite: bool,
    ignore_if_exists: bool,
};
const CreateFile = struct {
    kind: string,
    uri: string,
    options: *CreateFileOptions,
};
const RenameFileOptions = struct {
    overwrite: bool,
    ignore_if_exists: bool,
};
const RenameFile = struct {
    kind: string,
    old_uri: string,
    new_uri: string,
    options: *RenameFileOptions,
};
const DeleteFileOptions = struct {
    recursive: bool,
    ignore_if_not_exists: bool,
};
const DeleteFile = struct {
    kind: string,
    uri: string,
    options: *DeleteFileOptions,
};
const WorkspaceEdit = struct {};
const TextEditChange = struct {};
const TextDocumentIdentifier = struct {
    uri: string,
};
const VersionedTextDocumentIdentifier = struct {
    version: float64,
};
const TextDocumentItem = struct {
    uri: string,
    language_id: string,
    version: float64,
    text: string,
};
const MarkupContent = struct {
    kind: MarkupKind,
    value: string,
};
const CompletionItem = struct {
    label: string,
    kind: CompletionItemKind,
    detail: string,
    documentation: string,
    deprecated: bool,
    preselect: bool,
    sort_text: string,
    filter_text: string,
    insert_text: string,
    insert_text_format: InsertTextFormat,
    text_edit: *TextEdit,
    command: *Command,
};
const CompletionList = struct {
    is_incomplete: bool,
};
const Hover = struct {
    contents: MarkupContent,
    range: *Range,
};
const ParameterInformation = struct {
    label: string,
    documentation: string,
};
const SignatureInformation = struct {
    label: string,
    documentation: string,
};
const SignatureHelp = struct {
    active_signature: float64,
    active_parameter: float64,
};
const ReferenceContext = struct {
    include_declaration: bool,
};
const DocumentHighlight = struct {
    range: Range,
    kind: *DocumentHighlightKind,
};
const SymbolInformation = struct {
    name: string,
    kind: SymbolKind,
    deprecated: bool,
    location: Location,
    container_name: string,
};
const DocumentSymbol = struct {
    name: string,
    detail: string,
    kind: SymbolKind,
    deprecated: bool,
    range: Range,
    selection_range: Range,
};
const DocumentSymbolParams = struct {
    text_document: TextDocumentIdentifier,
};
const WorkspaceSymbolParams = struct {
    query: string,
};
const CodeActionContext = struct {};
const CodeAction = struct {
    title: string,
    kind: CodeActionKind,
    edit: *WorkspaceEdit,
    command: *Command,
};
const CodeLens = struct {
    range: Range,
    command: *Command,
};
const FormattingOptions = struct {
    tab_size: float64,
    insert_spaces: bool,
    trim_trailing_whitespace: bool,
    insert_final_newline: bool,
    trim_final_newlines: bool,
};
const DocumentLink = struct {
    range: Range,
    target: string,
};
const TextDocument = struct {
    uri: string,
    language_id: string,
    version: float64,
    line_count: float64,
};
const TextDocumentChangeEvent = struct {
    document: TextDocument,
};
const TextDocumentWillSaveEvent = struct {
    document: TextDocument,
    reason: TextDocumentSaveReason,
};
const TextDocumentContentChangeEvent = struct {
    range: *Range,
    range_length: float64,
    text: string,
};
