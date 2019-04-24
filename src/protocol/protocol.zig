// Package protocol contains data types for LSP jsonrpcs
// generated automatically from vscode-languageserver-node
//  version of Tue Apr 23 2019 15:01:15 GMT+0300 (East Africa Time)
const std = @import("std");
const json = std.json;
const ArrayList = std.ArrayList;
pub const ImplementationClientCapabilities = struct {
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        implementation: ?Implementation,
        pub const Implementation = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
pub const ImplementationServerCapabilities = struct {
    implementation_provider: ?bool,
};
pub const TypeDefinitionClientCapabilities = struct {
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        type_definition: ?TypeDefinition,
        pub const TypeDefinition = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
pub const TypeDefinitionServerCapabilities = struct {
    type_definition_provider: ?bool,
};
pub const WorkspaceFoldersInitializeParams = struct {
    workspace_folders: ArrayList(WorkspaceFolder),
};
pub const WorkspaceFoldersClientCapabilities = struct {
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspace_folders: ?bool,
    };
};
pub const WorkspaceFoldersServerCapabilities = struct {
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspace_folders: ?WorkspaceFolders,
        pub const WorkspaceFolders = struct {
            supported: ?bool,
            change_notifications: ?[]const u8,
        };
    };
};
pub const WorkspaceFolder = struct {
    uri: []const u8,
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
    scope_uri: ?[]const u8,
    section: ?[]const u8,
};
pub const ConfigurationParams = struct {
    items: ArrayList(ConfigurationItem),
};
pub const ColorClientCapabilities = struct {
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        color_provider: ?ColorProvider,
        pub const ColorProvider = struct {
            dynamic_registration: ?bool,
        };
    };
};
pub const ColorProviderOptions = struct {};
pub const ColorServerCapabilities = struct {
    color_provider: ?bool,
};
pub const DocumentColorParams = struct {
    text_document: TextDocumentIdentifier,
};
pub const ColorPresentationParams = struct {
    text_document: TextDocumentIdentifier,
    color: Color,
    range: Range,
};
pub const FoldingRangeClientCapabilities = struct {
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        folding_range: ?FoldingRange,
        pub const FoldingRange = struct {
            dynamic_registration: ?bool,
            range_limit: ?f64,
            line_folding_only: ?bool,
        };
    };
};
pub const FoldingRangeProviderOptions = struct {};
pub const FoldingRangeServerCapabilities = struct {
    folding_range_provider: ?bool,
};
pub const FoldingRange = struct {
    start_line: f64,
    start_character: ?f64,
    end_line: f64,
    end_character: ?f64,
    kind: ?[]const u8,
};
pub const FoldingRangeParams = struct {
    text_document: TextDocumentIdentifier,
};
pub const DeclarationClientCapabilities = struct {
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        declaration: ?Declaration,
        pub const Declaration = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
pub const DeclarationServerCapabilities = struct {
    declaration_provider: ?bool,
};
pub const Registration = struct {
    id: []const u8,
    method: []const u8,
    register_options: ?json.Value,
};
pub const RegistrationParams = struct {
    registrations: ArrayList(Registration),
};
pub const Unregistration = struct {
    id: []const u8,
    method: []const u8,
};
pub const UnregistrationParams = struct {
    unregisterations: ArrayList(Unregistration),
};
pub const TextDocumentPositionParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
};
pub const WorkspaceClientCapabilities = struct {
    apply_edit: ?bool,
    workspace_edit: ?WorkspaceEdit,
    pub const WorkspaceEdit = struct {
        document_changes: ?bool,
        resource_operations: ?ArrayList(ResourceOperationKind),
        failure_handling: ?FailureHandlingKind,
    };
    did_change_configuration: ?DidChangeConfiguration,
    pub const DidChangeConfiguration = struct {
        dynamic_registration: ?bool,
    };
    did_change_watched_files: ?DidChangeWatchedFiles,
    pub const DidChangeWatchedFiles = struct {
        dynamic_registration: ?bool,
    };
    symbol: ?Symbol,
    pub const Symbol = struct {
        dynamic_registration: ?bool,
        symbol_kind: ?SymbolKind,
        pub const SymbolKind = struct {
            value_set: ?ArrayList(SymbolKind),
        };
    };
    execute_command: ?ExecuteCommand,
    pub const ExecuteCommand = struct {
        dynamic_registration: ?bool,
    };
};
pub const TextDocumentClientCapabilities = struct {
    synchronization: ?Synchronization,
    pub const Synchronization = struct {
        dynamic_registration: ?bool,
        will_save: ?bool,
        will_save_wait_until: ?bool,
        did_save: ?bool,
    };
    completion: ?Completion,
    pub const Completion = struct {
        dynamic_registration: ?bool,
        completion_item: ?CompletionItem,
        pub const CompletionItem = struct {
            snippet_support: ?bool,
            commit_characters_support: ?bool,
            documentation_format: ?ArrayList(MarkupKind),
            deprecated_support: ?bool,
            preselect_support: ?bool,
        };
        completion_item_kind: ?CompletionItemKind,
        pub const CompletionItemKind = struct {
            value_set: ?ArrayList(CompletionItemKind),
        };
        context_support: ?bool,
    };
    hover: ?Hover,
    pub const Hover = struct {
        dynamic_registration: ?bool,
        content_format: ?ArrayList(MarkupKind),
    };
    signature_help: ?SignatureHelp,
    pub const SignatureHelp = struct {
        dynamic_registration: ?bool,
        signature_information: ?SignatureInformation,
        pub const SignatureInformation = struct {
            documentation_format: ?ArrayList(MarkupKind),
            parameter_information: ?ParameterInformation,
            pub const ParameterInformation = struct {
                label_offset_support: ?bool,
            };
        };
    };
    references: ?References,
    pub const References = struct {
        dynamic_registration: ?bool,
    };
    document_highlight: ?DocumentHighlight,
    pub const DocumentHighlight = struct {
        dynamic_registration: ?bool,
    };
    document_symbol: ?DocumentSymbol,
    pub const DocumentSymbol = struct {
        dynamic_registration: ?bool,
        symbol_kind: ?SymbolKind,
        pub const SymbolKind = struct {
            value_set: ?ArrayList(SymbolKind),
        };
        hierarchical_document_symbol_support: ?bool,
    };
    formatting: ?Formatting,
    pub const Formatting = struct {
        dynamic_registration: ?bool,
    };
    range_formatting: ?RangeFormatting,
    pub const RangeFormatting = struct {
        dynamic_registration: ?bool,
    };
    on_type_formatting: ?OnTypeFormatting,
    pub const OnTypeFormatting = struct {
        dynamic_registration: ?bool,
    };
    definition: ?Definition,
    pub const Definition = struct {
        dynamic_registration: ?bool,
        link_support: ?bool,
    };
    code_action: ?CodeAction,
    pub const CodeAction = struct {
        dynamic_registration: ?bool,
        code_action_literal_support: ?CodeActionLiteralSupport,
        pub const CodeActionLiteralSupport = struct {
            code_action_kind: CodeActionKind,
            pub const CodeActionKind = struct {
                value_set: ArrayList(CodeActionKind),
            };
        };
    };
    code_lens: ?CodeLens,
    pub const CodeLens = struct {
        dynamic_registration: ?bool,
    };
    document_link: ?DocumentLink,
    pub const DocumentLink = struct {
        dynamic_registration: ?bool,
    };
    rename: ?Rename,
    pub const Rename = struct {
        dynamic_registration: ?bool,
        prepare_support: ?bool,
    };
    publish_diagnostics: ?PublishDiagnostics,
    pub const PublishDiagnostics = struct {
        related_information: ?bool,
        tag_support: ?bool,
    };
};
pub const WindowClientCapabilities = struct {
    progress: ?bool,
};
pub const InnerClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    text_document: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
};
pub const ClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    text_document: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        implementation: ?Implementation,
        pub const Implementation = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        type_definition: ?TypeDefinition,
        pub const TypeDefinition = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspace_folders: ?bool,
    };
    workspace: ?Workspace,
    pub const Workspace = struct {
        configuration: ?bool,
    };
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        color_provider: ?ColorProvider,
        pub const ColorProvider = struct {
            dynamic_registration: ?bool,
        };
    };
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        folding_range: ?FoldingRange,
        pub const FoldingRange = struct {
            dynamic_registration: ?bool,
            range_limit: ?f64,
            line_folding_only: ?bool,
        };
    };
    text_document: ?TextDocument,
    pub const TextDocument = struct {
        declaration: ?Declaration,
        pub const Declaration = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
pub const StaticRegistrationOptions = struct {
    id: ?[]const u8,
};
pub const TextDocumentRegistrationOptions = struct {
    document_selector: DocumentSelector,
};
pub const CompletionOptions = struct {
    trigger_characters: ?ArrayList([]const u8),
    all_commit_characters: ?ArrayList([]const u8),
    resolve_provider: ?bool,
};
pub const SignatureHelpOptions = struct {
    trigger_characters: ?ArrayList([]const u8),
};
pub const CodeActionOptions = struct {
    code_action_kinds: ?ArrayList(CodeActionKind),
};
pub const CodeLensOptions = struct {
    resolve_provider: ?bool,
};
pub const DocumentOnTypeFormattingOptions = struct {
    first_trigger_character: []const u8,
    more_trigger_character: ?ArrayList([]const u8),
};
pub const RenameOptions = struct {
    prepare_provider: ?bool,
};
pub const DocumentLinkOptions = struct {
    resolve_provider: ?bool,
};
pub const ExecuteCommandOptions = struct {
    commands: ArrayList([]const u8),
};
pub const SaveOptions = struct {
    include_text: ?bool,
};
pub const TextDocumentSyncOptions = struct {
    open_close: ?bool,
    change: TextDocumentSyncKind,
    will_save: ?bool,
    will_save_wait_until: ?bool,
    save: ?SaveOptions,
};
pub const InnerServerCapabilities = struct {
    text_document_sync: ?json.Value,
    hover_provider: ?bool,
    completion_provider: ?CompletionOptions,
    signature_help_provider: ?SignatureHelpOptions,
    definition_provider: ?bool,
    references_provider: ?bool,
    document_highlight_provider: ?bool,
    document_symbol_provider: ?bool,
    workspace_symbol_provider: ?bool,
    code_action_provider: ?bool,
    code_lens_provider: ?CodeLensOptions,
    document_formatting_provider: ?bool,
    document_range_formatting_provider: ?bool,
    document_on_type_formatting_provider: ?DocumentOnTypeFormattingProvider,
    pub const DocumentOnTypeFormattingProvider = struct {
        first_trigger_character: []const u8,
        more_trigger_character: ?ArrayList([]const u8),
    };
    rename_provider: ?bool,
    document_link_provider: ?DocumentLinkOptions,
    execute_command_provider: ?ExecuteCommandOptions,
    experimental: ?json.Value,
};
pub const ServerCapabilities = struct {
    text_document_sync: ?json.Value,
    hover_provider: ?bool,
    completion_provider: ?CompletionOptions,
    signature_help_provider: ?SignatureHelpOptions,
    definition_provider: ?bool,
    references_provider: ?bool,
    document_highlight_provider: ?bool,
    document_symbol_provider: ?bool,
    workspace_symbol_provider: ?bool,
    code_action_provider: ?bool,
    code_lens_provider: ?CodeLensOptions,
    document_formatting_provider: ?bool,
    document_range_formatting_provider: ?bool,
    document_on_type_formatting_provider: ?DocumentOnTypeFormattingProvider,
    pub const DocumentOnTypeFormattingProvider = struct {
        first_trigger_character: []const u8,
        more_trigger_character: ?ArrayList([]const u8),
    };
    rename_provider: ?bool,
    document_link_provider: ?DocumentLinkOptions,
    execute_command_provider: ?ExecuteCommandOptions,
    experimental: ?json.Value,
    implementation_provider: ?bool,
    type_definition_provider: ?bool,
    workspace: ?Workspace,
    pub const Workspace = struct {
        workspace_folders: ?WorkspaceFolders,
        pub const WorkspaceFolders = struct {
            supported: ?bool,
            change_notifications: ?[]const u8,
        };
    };
    color_provider: ?bool,
    folding_range_provider: ?bool,
    declaration_provider: ?bool,
};
pub const InnerInitializeParams = struct {
    process_id: f64,
    root_path: ?[]const u8,
    root_uri: []const u8,
    capabilities: ClientCapabilities,
    initialization_options: ?json.Value,
    trace: ?[]const u8,
};
pub const InitializeParams = struct {
    process_id: f64,
    root_path: ?[]const u8,
    root_uri: []const u8,
    capabilities: ClientCapabilities,
    initialization_options: ?json.Value,
    trace: ?[]const u8,
    workspace_folders: ArrayList(WorkspaceFolder),
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
    text_document: TextDocumentItem,
};
pub const DidChangeTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
    content_changes: ArrayList(TextDocumentContentChangeEvent),
};
pub const TextDocumentChangeRegistrationOptions = struct {
    document_selector: DocumentSelector,
    sync_kind: TextDocumentSyncKind,
};
pub const DidCloseTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
};
pub const DidSaveTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
    text: ?[]const u8,
};
pub const TextDocumentSaveRegistrationOptions = struct {
    document_selector: DocumentSelector,
    include_text: ?bool,
};
pub const WillSaveTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
    reason: TextDocumentSaveReason,
};
pub const DidChangeWatchedFilesParams = struct {
    changes: ArrayList(FileEvent),
};
pub const FileEvent = struct {
    uri: []const u8,
    type: FileChangeType,
};
pub const DidChangeWatchedFilesRegistrationOptions = struct {
    watchers: ArrayList(FileSystemWatcher),
};
pub const FileSystemWatcher = struct {
    glob_pattern: []const u8,
    kind: ?f64,
};
pub const PublishDiagnosticsParams = struct {
    uri: []const u8,
    version: ?f64,
    diagnostics: ArrayList(Diagnostic),
};
pub const CompletionRegistrationOptions = struct {
    document_selector: DocumentSelector,
    trigger_characters: ?ArrayList([]const u8),
    all_commit_characters: ?ArrayList([]const u8),
    resolve_provider: ?bool,
};
pub const CompletionContext = struct {
    trigger_kind: CompletionTriggerKind,
    trigger_character: ?[]const u8,
};
pub const CompletionParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    context: ?CompletionContext,
};
pub const SignatureHelpRegistrationOptions = struct {
    document_selector: DocumentSelector,
    trigger_characters: ?ArrayList([]const u8),
};
pub const ReferenceParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    context: ReferenceContext,
};
pub const CodeActionParams = struct {
    text_document: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};
pub const CodeActionRegistrationOptions = struct {
    document_selector: DocumentSelector,
    code_action_kinds: ?ArrayList(CodeActionKind),
};
pub const CodeLensParams = struct {
    text_document: TextDocumentIdentifier,
};
pub const CodeLensRegistrationOptions = struct {
    document_selector: DocumentSelector,
    resolve_provider: ?bool,
};
pub const DocumentFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    options: FormattingOptions,
};
pub const DocumentRangeFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    range: Range,
    options: FormattingOptions,
};
pub const DocumentOnTypeFormattingParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    ch: []const u8,
    options: FormattingOptions,
};
pub const DocumentOnTypeFormattingRegistrationOptions = struct {
    document_selector: DocumentSelector,
    first_trigger_character: []const u8,
    more_trigger_character: ?ArrayList([]const u8),
};
pub const RenameParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    new_name: []const u8,
};
pub const RenameRegistrationOptions = struct {
    document_selector: DocumentSelector,
    prepare_provider: ?bool,
};
pub const DocumentLinkParams = struct {
    text_document: TextDocumentIdentifier,
};
pub const DocumentLinkRegistrationOptions = struct {
    document_selector: DocumentSelector,
    resolve_provider: ?bool,
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
    failure_reason: ?[]const u8,
    failed_change: ?f64,
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
    uri: []const u8,
    range: Range,
};
pub const LocationLink = struct {
    origin_selection_range: ?Range,
    target_uri: []const u8,
    target_range: Range,
    target_selection_range: Range,
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
    text_edit: ?TextEdit,
    additional_text_edits: ?ArrayList(TextEdit),
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
    related_information: ?ArrayList(DiagnosticRelatedInformation),
};
pub const Command = struct {
    title: []const u8,
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};
pub const TextEdit = struct {
    range: Range,
    new_text: []const u8,
};
pub const TextDocumentEdit = struct {
    text_document: VersionedTextDocumentIdentifier,
    edits: ArrayList(TextEdit),
};
pub const ResourceOperation = struct {
    kind: []const u8,
};
pub const CreateFileOptions = struct {
    overwrite: ?bool,
    ignore_if_exists: ?bool,
};
pub const CreateFile = struct {
    kind: []const u8,
    kind: []const u8,
    uri: []const u8,
    options: ?CreateFileOptions,
};
pub const RenameFileOptions = struct {
    overwrite: ?bool,
    ignore_if_exists: ?bool,
};
pub const RenameFile = struct {
    kind: []const u8,
    kind: []const u8,
    old_uri: []const u8,
    new_uri: []const u8,
    options: ?RenameFileOptions,
};
pub const DeleteFileOptions = struct {
    recursive: ?bool,
    ignore_if_not_exists: ?bool,
};
pub const DeleteFile = struct {
    kind: []const u8,
    kind: []const u8,
    uri: []const u8,
    options: ?DeleteFileOptions,
};
pub const WorkspaceEdit = struct {
    changes: ?json.ObjectMap,
    document_changes: ?ArrayList(TextDocumentEdit),
};
pub const TextEditChange = struct {};
pub const TextDocumentIdentifier = struct {
    uri: []const u8,
};
pub const VersionedTextDocumentIdentifier = struct {
    uri: []const u8,
    version: f64,
};
pub const TextDocumentItem = struct {
    uri: []const u8,
    language_id: []const u8,
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
    sort_text: ?[]const u8,
    filter_text: ?[]const u8,
    insert_text: ?[]const u8,
    insert_text_format: InsertTextFormat,
    text_edit: ?TextEdit,
    additional_text_edits: ?ArrayList(TextEdit),
    commit_characters: ?ArrayList([]const u8),
    command: ?Command,
    data: ?json.Value,
};
pub const CompletionList = struct {
    is_incomplete: bool,
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
    active_signature: f64,
    active_parameter: f64,
};
pub const ReferenceContext = struct {
    include_declaration: bool,
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
    container_name: ?[]const u8,
};
pub const DocumentSymbol = struct {
    name: []const u8,
    detail: ?[]const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    range: Range,
    selection_range: Range,
    children: ?ArrayList(DocumentSymbol),
};
pub const DocumentSymbolParams = struct {
    text_document: TextDocumentIdentifier,
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
    tab_size: f64,
    insert_spaces: bool,
    trim_trailing_whitespace: ?bool,
    insert_final_newline: ?bool,
    trim_final_newlines: ?bool,
    key: json.ObjectMap,
};
pub const DocumentLink = struct {
    range: Range,
    target: ?[]const u8,
    data: ?json.Value,
};
pub const TextDocument = struct {
    uri: []const u8,
    language_id: []const u8,
    version: f64,
    line_count: f64,
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
    range_length: ?f64,
    text: []const u8,
};
