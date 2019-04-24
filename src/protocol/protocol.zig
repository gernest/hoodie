// Package protocol contains data types for LSP jsonrpcs
// generated automatically from vscode-languageserver-node
//  version of Tue Apr 23 2019 15:01:15 GMT+0300 (East Africa Time)
const std = @import("std");
const json = std.json;
const ArrayList = std.ArrayList;
const ImplementationClientCapabilities = struct {
    text_document: ?TextDocument,
    const TextDocument = struct {
        implementation: ?Implementation,
        const Implementation = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
const ImplementationServerCapabilities = struct {
    implementation_provider: ?bool,
};
const TypeDefinitionClientCapabilities = struct {
    text_document: ?TextDocument,
    const TextDocument = struct {
        type_definition: ?TypeDefinition,
        const TypeDefinition = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
const TypeDefinitionServerCapabilities = struct {
    type_definition_provider: ?bool,
};
const WorkspaceFoldersInitializeParams = struct {
    workspace_folders: ArrayList(WorkspaceFolder),
};
const WorkspaceFoldersClientCapabilities = struct {
    workspace: ?Workspace,
    const Workspace = struct {
        workspace_folders: ?bool,
    };
};
const WorkspaceFoldersServerCapabilities = struct {
    workspace: ?Workspace,
    const Workspace = struct {
        workspace_folders: ?WorkspaceFolders,
        const WorkspaceFolders = struct {
            supported: ?bool,
            change_notifications: ?[]const u8,
        };
    };
};
const WorkspaceFolder = struct {
    uri: []const u8,
    name: []const u8,
};
const DidChangeWorkspaceFoldersParams = struct {
    event: WorkspaceFoldersChangeEvent,
};
const WorkspaceFoldersChangeEvent = struct {
    added: ArrayList(WorkspaceFolder),
    removed: ArrayList(WorkspaceFolder),
};
const ConfigurationClientCapabilities = struct {
    workspace: ?Workspace,
    const Workspace = struct {
        configuration: ?bool,
    };
};
const ConfigurationItem = struct {
    scope_uri: ?[]const u8,
    section: ?[]const u8,
};
const ConfigurationParams = struct {
    items: ArrayList(ConfigurationItem),
};
const ColorClientCapabilities = struct {
    text_document: ?TextDocument,
    const TextDocument = struct {
        color_provider: ?ColorProvider,
        const ColorProvider = struct {
            dynamic_registration: ?bool,
        };
    };
};
const ColorProviderOptions = struct {};
const ColorServerCapabilities = struct {
    color_provider: ?bool,
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
    text_document: ?TextDocument,
    const TextDocument = struct {
        folding_range: ?FoldingRange,
        const FoldingRange = struct {
            dynamic_registration: ?bool,
            range_limit: ?f64,
            line_folding_only: ?bool,
        };
    };
};
const FoldingRangeProviderOptions = struct {};
const FoldingRangeServerCapabilities = struct {
    folding_range_provider: ?bool,
};
const FoldingRange = struct {
    start_line: f64,
    start_character: ?f64,
    end_line: f64,
    end_character: ?f64,
    kind: ?[]const u8,
};
const FoldingRangeParams = struct {
    text_document: TextDocumentIdentifier,
};
const DeclarationClientCapabilities = struct {
    text_document: ?TextDocument,
    const TextDocument = struct {
        declaration: ?Declaration,
        const Declaration = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
const DeclarationServerCapabilities = struct {
    declaration_provider: ?bool,
};
const Registration = struct {
    id: []const u8,
    method: []const u8,
    register_options: ?json.Value,
};
const RegistrationParams = struct {
    registrations: ArrayList(Registration),
};
const Unregistration = struct {
    id: []const u8,
    method: []const u8,
};
const UnregistrationParams = struct {
    unregisterations: ArrayList(Unregistration),
};
const TextDocumentPositionParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
};
const WorkspaceClientCapabilities = struct {
    apply_edit: ?bool,
    workspace_edit: ?WorkspaceEdit,
    const WorkspaceEdit = struct {
        document_changes: ?bool,
        resource_operations: ?ArrayList(ResourceOperationKind),
        failure_handling: ?FailureHandlingKind,
    };
    did_change_configuration: ?DidChangeConfiguration,
    const DidChangeConfiguration = struct {
        dynamic_registration: ?bool,
    };
    did_change_watched_files: ?DidChangeWatchedFiles,
    const DidChangeWatchedFiles = struct {
        dynamic_registration: ?bool,
    };
    symbol: ?Symbol,
    const Symbol = struct {
        dynamic_registration: ?bool,
        symbol_kind: ?SymbolKind,
        const SymbolKind = struct {
            value_set: ?ArrayList(SymbolKind),
        };
    };
    execute_command: ?ExecuteCommand,
    const ExecuteCommand = struct {
        dynamic_registration: ?bool,
    };
};
const TextDocumentClientCapabilities = struct {
    synchronization: ?Synchronization,
    const Synchronization = struct {
        dynamic_registration: ?bool,
        will_save: ?bool,
        will_save_wait_until: ?bool,
        did_save: ?bool,
    };
    completion: ?Completion,
    const Completion = struct {
        dynamic_registration: ?bool,
        completion_item: ?CompletionItem,
        const CompletionItem = struct {
            snippet_support: ?bool,
            commit_characters_support: ?bool,
            documentation_format: ?ArrayList(MarkupKind),
            deprecated_support: ?bool,
            preselect_support: ?bool,
        };
        completion_item_kind: ?CompletionItemKind,
        const CompletionItemKind = struct {
            value_set: ?ArrayList(CompletionItemKind),
        };
        context_support: ?bool,
    };
    hover: ?Hover,
    const Hover = struct {
        dynamic_registration: ?bool,
        content_format: ?ArrayList(MarkupKind),
    };
    signature_help: ?SignatureHelp,
    const SignatureHelp = struct {
        dynamic_registration: ?bool,
        signature_information: ?SignatureInformation,
        const SignatureInformation = struct {
            documentation_format: ?ArrayList(MarkupKind),
            parameter_information: ?ParameterInformation,
            const ParameterInformation = struct {
                label_offset_support: ?bool,
            };
        };
    };
    references: ?References,
    const References = struct {
        dynamic_registration: ?bool,
    };
    document_highlight: ?DocumentHighlight,
    const DocumentHighlight = struct {
        dynamic_registration: ?bool,
    };
    document_symbol: ?DocumentSymbol,
    const DocumentSymbol = struct {
        dynamic_registration: ?bool,
        symbol_kind: ?SymbolKind,
        const SymbolKind = struct {
            value_set: ?ArrayList(SymbolKind),
        };
        hierarchical_document_symbol_support: ?bool,
    };
    formatting: ?Formatting,
    const Formatting = struct {
        dynamic_registration: ?bool,
    };
    range_formatting: ?RangeFormatting,
    const RangeFormatting = struct {
        dynamic_registration: ?bool,
    };
    on_type_formatting: ?OnTypeFormatting,
    const OnTypeFormatting = struct {
        dynamic_registration: ?bool,
    };
    definition: ?Definition,
    const Definition = struct {
        dynamic_registration: ?bool,
        link_support: ?bool,
    };
    code_action: ?CodeAction,
    const CodeAction = struct {
        dynamic_registration: ?bool,
        code_action_literal_support: ?CodeActionLiteralSupport,
        const CodeActionLiteralSupport = struct {
            code_action_kind: CodeActionKind,
            const CodeActionKind = struct {
                value_set: ArrayList(CodeActionKind),
            };
        };
    };
    code_lens: ?CodeLens,
    const CodeLens = struct {
        dynamic_registration: ?bool,
    };
    document_link: ?DocumentLink,
    const DocumentLink = struct {
        dynamic_registration: ?bool,
    };
    rename: ?Rename,
    const Rename = struct {
        dynamic_registration: ?bool,
        prepare_support: ?bool,
    };
    publish_diagnostics: ?PublishDiagnostics,
    const PublishDiagnostics = struct {
        related_information: ?bool,
        tag_support: ?bool,
    };
};
const WindowClientCapabilities = struct {
    progress: ?bool,
};
const InnerClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    text_document: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
};
const ClientCapabilities = struct {
    workspace: ?WorkspaceClientCapabilities,
    text_document: ?TextDocumentClientCapabilities,
    window: ?WindowClientCapabilities,
    experimental: ?json.Value,
    text_document: ?TextDocument,
    const TextDocument = struct {
        implementation: ?Implementation,
        const Implementation = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
    text_document: ?TextDocument,
    const TextDocument = struct {
        type_definition: ?TypeDefinition,
        const TypeDefinition = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
    workspace: ?Workspace,
    const Workspace = struct {
        workspace_folders: ?bool,
    };
    workspace: ?Workspace,
    const Workspace = struct {
        configuration: ?bool,
    };
    text_document: ?TextDocument,
    const TextDocument = struct {
        color_provider: ?ColorProvider,
        const ColorProvider = struct {
            dynamic_registration: ?bool,
        };
    };
    text_document: ?TextDocument,
    const TextDocument = struct {
        folding_range: ?FoldingRange,
        const FoldingRange = struct {
            dynamic_registration: ?bool,
            range_limit: ?f64,
            line_folding_only: ?bool,
        };
    };
    text_document: ?TextDocument,
    const TextDocument = struct {
        declaration: ?Declaration,
        const Declaration = struct {
            dynamic_registration: ?bool,
            link_support: ?bool,
        };
    };
};
const StaticRegistrationOptions = struct {
    id: ?[]const u8,
};
const TextDocumentRegistrationOptions = struct {
    document_selector: DocumentSelector,
};
const CompletionOptions = struct {
    trigger_characters: ?ArrayList([]const u8),
    all_commit_characters: ?ArrayList([]const u8),
    resolve_provider: ?bool,
};
const SignatureHelpOptions = struct {
    trigger_characters: ?ArrayList([]const u8),
};
const CodeActionOptions = struct {
    code_action_kinds: ?ArrayList(CodeActionKind),
};
const CodeLensOptions = struct {
    resolve_provider: ?bool,
};
const DocumentOnTypeFormattingOptions = struct {
    first_trigger_character: []const u8,
    more_trigger_character: ?ArrayList([]const u8),
};
const RenameOptions = struct {
    prepare_provider: ?bool,
};
const DocumentLinkOptions = struct {
    resolve_provider: ?bool,
};
const ExecuteCommandOptions = struct {
    commands: ArrayList([]const u8),
};
const SaveOptions = struct {
    include_text: ?bool,
};
const TextDocumentSyncOptions = struct {
    open_close: ?bool,
    change: TextDocumentSyncKind,
    will_save: ?bool,
    will_save_wait_until: ?bool,
    save: ?SaveOptions,
};
const InnerServerCapabilities = struct {
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
    const DocumentOnTypeFormattingProvider = struct {
        first_trigger_character: []const u8,
        more_trigger_character: ?ArrayList([]const u8),
    };
    rename_provider: ?bool,
    document_link_provider: ?DocumentLinkOptions,
    execute_command_provider: ?ExecuteCommandOptions,
    experimental: ?json.Value,
};
const ServerCapabilities = struct {
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
    const DocumentOnTypeFormattingProvider = struct {
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
    const Workspace = struct {
        workspace_folders: ?WorkspaceFolders,
        const WorkspaceFolders = struct {
            supported: ?bool,
            change_notifications: ?[]const u8,
        };
    };
    color_provider: ?bool,
    folding_range_provider: ?bool,
    declaration_provider: ?bool,
};
const InnerInitializeParams = struct {
    process_id: f64,
    root_path: ?[]const u8,
    root_uri: []const u8,
    capabilities: ClientCapabilities,
    initialization_options: ?json.Value,
    trace: ?[]const u8,
};
const InitializeParams = struct {
    process_id: f64,
    root_path: ?[]const u8,
    root_uri: []const u8,
    capabilities: ClientCapabilities,
    initialization_options: ?json.Value,
    trace: ?[]const u8,
    workspace_folders: ArrayList(WorkspaceFolder),
};
const InitializeResult = struct {
    capabilities: ServerCapabilities,
    custom: json.ObjectMap,
};
const InitializedParams = struct {};
const DidChangeConfigurationRegistrationOptions = struct {
    section: ?[]const u8,
};
const DidChangeConfigurationParams = struct {
    settings: json.Value,
};
const ShowMessageParams = struct {
    type: MessageType,
    message: []const u8,
};
const MessageActionItem = struct {
    title: []const u8,
};
const ShowMessageRequestParams = struct {
    type: MessageType,
    message: []const u8,
    actions: ?ArrayList(MessageActionItem),
};
const LogMessageParams = struct {
    type: MessageType,
    message: []const u8,
};
const DidOpenTextDocumentParams = struct {
    text_document: TextDocumentItem,
};
const DidChangeTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
    content_changes: ArrayList(TextDocumentContentChangeEvent),
};
const TextDocumentChangeRegistrationOptions = struct {
    document_selector: DocumentSelector,
    sync_kind: TextDocumentSyncKind,
};
const DidCloseTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
};
const DidSaveTextDocumentParams = struct {
    text_document: VersionedTextDocumentIdentifier,
    text: ?[]const u8,
};
const TextDocumentSaveRegistrationOptions = struct {
    document_selector: DocumentSelector,
    include_text: ?bool,
};
const WillSaveTextDocumentParams = struct {
    text_document: TextDocumentIdentifier,
    reason: TextDocumentSaveReason,
};
const DidChangeWatchedFilesParams = struct {
    changes: ArrayList(FileEvent),
};
const FileEvent = struct {
    uri: []const u8,
    type: FileChangeType,
};
const DidChangeWatchedFilesRegistrationOptions = struct {
    watchers: ArrayList(FileSystemWatcher),
};
const FileSystemWatcher = struct {
    glob_pattern: []const u8,
    kind: ?f64,
};
const PublishDiagnosticsParams = struct {
    uri: []const u8,
    version: ?f64,
    diagnostics: ArrayList(Diagnostic),
};
const CompletionRegistrationOptions = struct {
    document_selector: DocumentSelector,
    trigger_characters: ?ArrayList([]const u8),
    all_commit_characters: ?ArrayList([]const u8),
    resolve_provider: ?bool,
};
const CompletionContext = struct {
    trigger_kind: CompletionTriggerKind,
    trigger_character: ?[]const u8,
};
const CompletionParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    context: ?CompletionContext,
};
const SignatureHelpRegistrationOptions = struct {
    document_selector: DocumentSelector,
    trigger_characters: ?ArrayList([]const u8),
};
const ReferenceParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    context: ReferenceContext,
};
const CodeActionParams = struct {
    text_document: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};
const CodeActionRegistrationOptions = struct {
    document_selector: DocumentSelector,
    code_action_kinds: ?ArrayList(CodeActionKind),
};
const CodeLensParams = struct {
    text_document: TextDocumentIdentifier,
};
const CodeLensRegistrationOptions = struct {
    document_selector: DocumentSelector,
    resolve_provider: ?bool,
};
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
    ch: []const u8,
    options: FormattingOptions,
};
const DocumentOnTypeFormattingRegistrationOptions = struct {
    document_selector: DocumentSelector,
    first_trigger_character: []const u8,
    more_trigger_character: ?ArrayList([]const u8),
};
const RenameParams = struct {
    text_document: TextDocumentIdentifier,
    position: Position,
    new_name: []const u8,
};
const RenameRegistrationOptions = struct {
    document_selector: DocumentSelector,
    prepare_provider: ?bool,
};
const DocumentLinkParams = struct {
    text_document: TextDocumentIdentifier,
};
const DocumentLinkRegistrationOptions = struct {
    document_selector: DocumentSelector,
    resolve_provider: ?bool,
};
const ExecuteCommandParams = struct {
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};
const ExecuteCommandRegistrationOptions = struct {
    commands: ArrayList([]const u8),
};
const ApplyWorkspaceEditParams = struct {
    label: ?[]const u8,
    edit: WorkspaceEdit,
};
const ApplyWorkspaceEditResponse = struct {
    applied: bool,
    failure_reason: ?[]const u8,
    failed_change: ?f64,
};
const Position = struct {
    line: f64,
    character: f64,
};
const Range = struct {
    start: Position,
    end: Position,
};
const Location = struct {
    uri: []const u8,
    range: Range,
};
const LocationLink = struct {
    origin_selection_range: ?Range,
    target_uri: []const u8,
    target_range: Range,
    target_selection_range: Range,
};
const Color = struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};
const ColorInformation = struct {
    range: Range,
    color: Color,
};
const ColorPresentation = struct {
    label: []const u8,
    text_edit: ?TextEdit,
    additional_text_edits: ?ArrayList(TextEdit),
};
const DiagnosticRelatedInformation = struct {
    location: Location,
    message: []const u8,
};
const Diagnostic = struct {
    range: Range,
    severity: DiagnosticSeverity,
    code: ?json.Value,
    source: ?[]const u8,
    message: []const u8,
    tags: ?ArrayList(DiagnosticTag),
    related_information: ?ArrayList(DiagnosticRelatedInformation),
};
const Command = struct {
    title: []const u8,
    command: []const u8,
    arguments: ?ArrayList(interface{}),
};
const TextEdit = struct {
    range: Range,
    new_text: []const u8,
};
const TextDocumentEdit = struct {
    text_document: VersionedTextDocumentIdentifier,
    edits: ArrayList(TextEdit),
};
const ResourceOperation = struct {
    kind: []const u8,
};
const CreateFileOptions = struct {
    overwrite: ?bool,
    ignore_if_exists: ?bool,
};
const CreateFile = struct {
    kind: []const u8,
    kind: []const u8,
    uri: []const u8,
    options: ?CreateFileOptions,
};
const RenameFileOptions = struct {
    overwrite: ?bool,
    ignore_if_exists: ?bool,
};
const RenameFile = struct {
    kind: []const u8,
    kind: []const u8,
    old_uri: []const u8,
    new_uri: []const u8,
    options: ?RenameFileOptions,
};
const DeleteFileOptions = struct {
    recursive: ?bool,
    ignore_if_not_exists: ?bool,
};
const DeleteFile = struct {
    kind: []const u8,
    kind: []const u8,
    uri: []const u8,
    options: ?DeleteFileOptions,
};
const WorkspaceEdit = struct {
    changes: ?json.ObjectMap,
    document_changes: ?ArrayList(TextDocumentEdit),
};
const TextEditChange = struct {};
const TextDocumentIdentifier = struct {
    uri: []const u8,
};
const VersionedTextDocumentIdentifier = struct {
    uri: []const u8,
    version: f64,
};
const TextDocumentItem = struct {
    uri: []const u8,
    language_id: []const u8,
    version: f64,
    text: []const u8,
};
const MarkupContent = struct {
    kind: MarkupKind,
    value: []const u8,
};
const CompletionItem = struct {
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
const CompletionList = struct {
    is_incomplete: bool,
    items: ArrayList(CompletionItem),
};
const Hover = struct {
    contents: MarkupContent,
    range: ?Range,
};
const ParameterInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
};
const SignatureInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
    parameters: ?ArrayList(ParameterInformation),
};
const SignatureHelp = struct {
    signatures: ArrayList(SignatureInformation),
    active_signature: f64,
    active_parameter: f64,
};
const ReferenceContext = struct {
    include_declaration: bool,
};
const DocumentHighlight = struct {
    range: Range,
    kind: ?DocumentHighlightKind,
};
const SymbolInformation = struct {
    name: []const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    location: Location,
    container_name: ?[]const u8,
};
const DocumentSymbol = struct {
    name: []const u8,
    detail: ?[]const u8,
    kind: SymbolKind,
    deprecated: ?bool,
    range: Range,
    selection_range: Range,
    children: ?ArrayList(DocumentSymbol),
};
const DocumentSymbolParams = struct {
    text_document: TextDocumentIdentifier,
};
const WorkspaceSymbolParams = struct {
    query: []const u8,
};
const CodeActionContext = struct {
    diagnostics: ArrayList(Diagnostic),
    only: ?ArrayList(CodeActionKind),
};
const CodeAction = struct {
    title: []const u8,
    kind: CodeActionKind,
    diagnostics: ?ArrayList(Diagnostic),
    edit: ?WorkspaceEdit,
    command: ?Command,
};
const CodeLens = struct {
    range: Range,
    command: ?Command,
    data: ?json.Value,
};
const FormattingOptions = struct {
    tab_size: f64,
    insert_spaces: bool,
    trim_trailing_whitespace: ?bool,
    insert_final_newline: ?bool,
    trim_final_newlines: ?bool,
    key: json.ObjectMap,
};
const DocumentLink = struct {
    range: Range,
    target: ?[]const u8,
    data: ?json.Value,
};
const TextDocument = struct {
    uri: []const u8,
    language_id: []const u8,
    version: f64,
    line_count: f64,
};
const TextDocumentChangeEvent = struct {
    document: TextDocument,
};
const TextDocumentWillSaveEvent = struct {
    document: TextDocument,
    reason: TextDocumentSaveReason,
};
const TextDocumentContentChangeEvent = struct {
    range: ?Range,
    range_length: ?f64,
    text: []const u8,
};
