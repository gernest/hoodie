const types = @import("protocol/types.zig");

pub const Server = struct {
    pub fn DidChangeWorkspaceFolders(self: *Server, param: *DidChangeWorkspaceFoldersParams) !void {}
    pub fn Initialized(self: *Server, param: *InitializedParams) !void {}
    pub fn Exit(self: *Server) !void {}
    pub fn DidChangeConfiguration(self: *Server, param: *DidChangeConfigurationParams) !void {}
    pub fn DidOpen(self: *Server, param: *DidOpenTextDocumentParams) !void {}
    pub fn DidChange(self: *Server, param: *DidChangeTextDocumentParams) !void {}
    pub fn DidClose(self: *Server, param: *DidCloseTextDocumentParams) !void {}
    pub fn DidSave(self: *Server, param: *DidSaveTextDocumentParams) !void {}
    pub fn WillSave(self: *Server, param: *WillSaveTextDocumentParams) !void {}
    pub fn DidChangeWatchedFiles(self: *Server, param: *DidChangeWatchedFilesParams) !void {}
    pub fn SetTraceNotification(self: *Server, param: *SetTraceParams) !void {}
    pub fn LogTraceNotification(self: *Server, param: *LogTraceParams) !void {}
    pub fn Implementation(self: *Server, param: *TextDocumentPositionParams) !ArrayList(Location) {}
    pub fn TypeDefinition(self: *Server, param: *TextDocumentPositionParams) !ArrayList(Location) {}
    pub fn DocumentColor(self: *Server, param: *DocumentColorParams) !ArrayList(ColorInformation) {}
    pub fn ColorPresentation(self: *Server, param: *ColorPresentationParams) !ArrayList(ColorPresentation) {}
    pub fn FoldingRange(self: *Server, param: *FoldingRangeParams) !ArrayList(FoldingRange) {}
    pub fn Declaration(self: *Server, param: *TextDocumentPositionParams) !ArrayList(DeclarationLink) {}
    pub fn SelectionRange(self: *Server, param: *SelectionRangeParams) !ArrayList(SelectionRange) {}
    pub fn Initialize(self: *Server, param: *InitializeParams) !*InitializeResult {}
    pub fn Shutdown(self: *Server) !void {}
    pub fn WillSaveWaitUntil(self: *Server, param: *WillSaveTextDocumentParams) ArrayList(TextEdit) {}
    pub fn Completion(self: *Server, param: *CompletionParams) !*CompletionList {}
    pub fn Resolve(self: *Server, param: *CompletionItem) !*CompletionItem {}
    pub fn Hover(self: *Server, param: *TextDocumentPositionParams) !*Hover {}
    pub fn SignatureHelp(self: *Server, param: *TextDocumentPositionParams) !*SignatureHelp {}
    pub fn Definition(self: *Server, param: *TextDocumentPositionParams) !ArrayList(Location) {}
    pub fn References(self: *Server, param: *ReferenceParams) !ArrayList(Location) {}
    pub fn DocumentHighlight(self: *Server, param: *TextDocumentPositionParams) !ArrayList(DocumentHighlight) {}
    pub fn DocumentSymbol(self: *Server, param: *DocumentSymbolParams) !ArrayList(DocumentSymbol) {}
    pub fn Symbol(self: *Server, param: *WorkspaceSymbolParams) !ArrayList(SymbolInformation) {}
    pub fn CodeAction(self: *Server, param: *CodeActionParams) !ArrayList(CodeAction) {}
    pub fn CodeLens(self: *Server, param: *CodeLensParams) !ArrayList(CodeLens) {}
    pub fn ResolveCodeLens(self: *Server, param: *CodeLens) !*CodeLens {}
    pub fn Formatting(self: *Server, param: *DocumentFormattingParams) !ArrayList(TextEdit) {}
    pub fn RangeFormatting(self: *Server, param: *DocumentRangeFormattingParams) !ArrayList(TextEdit) {}
    pub fn OnTypeFormatting(self: *Server, param: *DocumentOnTypeFormattingParams) !ArrayList(TextEdit) {}
    pub fn Rename(self: *Server, param: *RenameParams) !*WorkspaceEdit {}
    pub fn PrepareRename(self: *Server, param: *TextDocumentPositionParams) !*Range {}
    pub fn DocumentLink(self: *Server, param: *DocumentLinkParams) !ArrayList(DocumentLink) {}
    pub fn ResolveDocumentLink(self: *Server, param: *DocumentLink) !*DocumentLink {}
    pub fn ExecuteCommand(self: *Server, param: *ExecuteCommandParams) !json.Value {}
};
