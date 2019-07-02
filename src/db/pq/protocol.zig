const std = @import("std");
const io = std.io;
const mem = std.mem;

pub const PROTOCOL_VERSION = 196608;
pub const SSL_REQUEST_CODE = 80877103;

pub const SSL_ALLOWED = 'S';
pub const SSL_NOT_ALLOWED = 'N';

pub const Type = struct {
    pub const AUTHENTICATION: u8 = 'R';
    pub const ERROR: u8 = 'E';
    pub const EMPTY_QUERY: u8 = 'I';
    pub const DESCRIBE: u8 = 'D';
    pub const RAW_DESCRIPTION: u8 = 'T';
    pub const DATA_RAW: u8 = 'D';
    pub const QUERY: u8 = 'Q';
    pub const COMMAND_COMPLETE: u8 = 'C';
    pub const TERMINATE: u8 = 'X';
    pub const NOTICE: u8 = 'N';
    pub const PASSWORD: u8 = 'p';
    pub const ReadyForQueryMessage: u8 = 'Z';
};

const Auth = struct {
    pub const OK = 0;
    pub const KERBEROS_v5 = 2;
    pub const CLEAR_TEXT = 3;
    pub const MD5 = 5;
    pub const SCM = 6;
    pub const GSS = 7;
    pub const GSS_CONTINUE = 8;
    pub const SSPI = 9;
};

pub const Offset = enum {
    Startup,
    Base,
};

pub const Severity = struct {
    pub const FATAL = "FATAL";
    pub const PANIC = "PANIC";
    pub const WARNING = "WARNING";
    pub const NOTICE = "NOTICE";
    pub const DEBUG = "DEBUG";
    pub const INFO = "INFO";
    pub const LOG = "LOG";
};

pub const Field = struct {
    pub const SEVERITY: u8 = 'S';
    pub const CODE: u8 = 'C';
    pub const MESSAGE: u8 = 'M';
    pub const MESSAGE_DETAIL: u8 = 'D';
    pub const MESSAGE_HINT: u8 = 'H';
    pub const POSITION: u8 = 'P';
    pub const INTERNAL_POSITION: u8 = 'p';
    pub const INTERNAL_QUERY: u8 = 'q';
    pub const WHERE: u8 = 'W';
    pub const SCHEME_NAME: u8 = 's';
    pub const TABLE_NAME: u8 = 't';
    pub const COLUMN_NAME: u8 = 'c';
    pub const DETAIL_TYPE_NAME: u8 = 'd';
    pub const CONSTRAINT_NAME: u8 = 'n';
    pub const FILE: u8 = 'F';
    pub const LINE: u8 = 'L';
    pub const ROUTINE: u8 = 'R';
};

const Code = struct {
    // Class 00 — Successful Completion
    pub const SuccessfulCompletion = "00000"; // successful_completion
    // Class 01 — Warning
    pub const Warning = "01000"; // warning
    pub const WarningDynamicResultSetsReturned = "0100C"; // dynamic_result_sets_returned
    pub const WarningImplicitZeroBitPadding = "01008"; // implicit_zero_bit_padding
    pub const WarningNullValueEliminatedInSetFunction = "01003"; // null_value_eliminated_in_set_function
    pub const WarningPrivilegeNotGranted = "01007"; // privilege_not_granted
    pub const WarningPrivilegeNotRevoked = "01006"; // privilege_not_revoked
    pub const WarningStringDataRightTruncation = "01004"; // string_data_right_truncation
    pub const WarningDeprecatedFeature = "01P01"; // deprecated_feature
    // Class 02 — No Data (this is also a warning class per the SQL standard)
    pub const NoData = "02000"; // no_data;
    pub const NoAdditionalDynamicResultSetsReturned = "02001"; // no_additional_dynamic_result_sets_returned
    // Class 03 — SQL Statement Not Yet Complete
    pub const SQLStatementNotYetComplete = "03000"; // sql_statement_not_yet_complete
    // Class 08 — Connection Exception
    pub const ConnectionException = "08000"; // connection_exception
    pub const ConnectionDoesNotExist = "08003"; // connection_does_not_exist
    pub const ConnectionFailure = "08006"; // connection_failure
    pub const SQLClientUnableToEstablishSQLConnection = "08001"; // sqlclient_unable_to_establish_sqlconnection
    pub const SQLServerRejectedEstablishementOfSQLConnection = "08004"; // sqlserver_rejected_establishment_of_sqlconnection
    pub const TransactionResolutionUnknown = "08007"; // transaction_resolution_unknown
    pub const ProtocolViolation = "08P01"; // protocol_violation
    // Class 09 — Triggered Action Exception
    pub const TriggeredActionException = "09000"; // triggered_action_exception
    // Class 0A — Feature Not Supported
    pub const FeatureNotSupported = "0A000"; // feature_not_supported
    // Class 0B — Invalid Transaction Initiation
    pub const InvalidTransactionInitiation = "0B000"; // invalid_transaction_initiation
    // Class 0F — Locator Exception
    pub const LocatorException = "0F000"; // locator_exception
    pub const InvalidLocatorSpecification = "0F001"; // invalid_locator_specification
    // Class 0L — Invalid Grantor
    pub const InvalidGrantor = "0L000"; // invalid_grantor
    pub const InvalidGrantOperation = "0LP01"; // invalid_grant_operation
    // Class 0P — Invalid Role Specification
    pub const InvalidRoleSpecification = "0P000"; // invalid_role_specification
    // Class 0Z — Diagnostics Exception
    pub const DiagnosticsException = "0Z000"; // diagnostics_exception
    pub const StackedDiagnosticsAccessedWithoutActiveHandler = "0Z002"; // stacked_diagnostics_accessed_without_active_handler
    // Class 20 — Case Not Found
    pub const CaseNotFound = "20000"; // case_not_found
    // Class 21 — Cardinality Violation
    pub const CardinalityViolation = "21000"; // cardinality_violation
    // Class 22 — Data Exception
    pub const DataException = "22000"; // data_exception
    pub const ArraySubscriptError = "2202E"; // array_subscript_error
    pub const CharacterNotInRepertoire = "22021"; // character_not_in_repertoire
    pub const DatatimeFieldOverflow = "22008"; // datetime_field_overflow
    pub const DivisionByZero = "22012"; // division_by_zero
    pub const ErrorInAssignment = "22005"; // error_in_assignment
    pub const EscapeCharacterConflict = "2200B"; // escape_character_conflict
    pub const IndicatorOverflow = "22022"; // indicator_overflow
    pub const IntervalFieldOverflow = "22015"; // interval_field_overflow
    pub const InvalidArgumentForLogarithm = "2201E"; // invalid_argument_for_logarithm
    pub const InvalidArgumentForNTileFunction = "22014"; // invalid_argument_for_ntile_function
    pub const InvalidArgumentForNthValueFunction = "22016"; // invalid_argument_for_nth_value_function
    pub const InvalidArgumentForPowerFunction = "2201F"; // invalid_argument_for_power_function
    pub const InvalidArgumentForWidthBucketFunction = "2201G"; // invalid_argument_for_width_bucket_function
    pub const InvalidCharacterValueForCast = "22018"; // invalid_character_value_for_cast
    pub const InvalidDatatimeFormat = "22007"; // invalid_datetime_format
    pub const InvalidEscapeCharacter = "22019"; // invalid_escape_character
    pub const InvalidEscapeOctet = "2200D"; // invalid_escape_octet
    pub const InvalidEscapeSequence = "22025"; // invalid_escape_sequence
    pub const NonStandardUseOfEscapeCharacter = "22P06"; // nonstandard_use_of_escape_character
    pub const InvalidIndicatorParameterValue = "22010"; // invalid_indicator_parameter_value
    pub const InvalidParameterValue = "22023"; // invalid_parameter_value
    pub const InvalidRegularExpression = "2201B"; // invalid_regular_expression
    pub const InvalidRowCountInLimitClause = "2201W"; // invalid_row_count_in_limit_clause
    pub const InvalidRowCountInResultOffsetClause = "2201X"; // invalid_row_count_in_result_offset_clause
    pub const InvalidTablesampleArgument = "2202H"; // invalid_tablesample_argument
    pub const InvalidTablesampleRepeat = "2202G"; // invalid_tablesample_repeat
    pub const InvalidTimeZoneDisplacementValue = "22009"; // invalid_time_zone_displacement_value
    pub const InvalidInvalidUseOfEscapeCharacter = "2200C"; // invalid_use_of_escape_character
    pub const MostSpecificTypeMismatch = "2200G"; // most_specific_type_mismatch
    pub const NullValueNotAllowed = "22004"; // null_value_not_allowed
    pub const NullValueNoIndicatorParameter = "22002"; // null_value_no_indicator_parameter
    pub const NumericValueOutOfRange = "22003"; // numeric_value_out_of_range
    pub const StringDataLengthMismatch = "22026"; // string_data_length_mismatch
    pub const StringDataRightTruncation = "22001"; // string_data_right_truncation
    pub const SubstringError = "22011"; // substring_error
    pub const TrimError = "22027"; // trim_error
    pub const UntermincatedCString = "22024"; // unterminated_c_string
    pub const ZeroLengthCharacterString = "2200F"; // zero_length_character_string
    pub const FloatingPointException = "22P01"; // floating_point_exception
    pub const InvalidTextRepresentation = "22P02"; // invalid_text_representation
    pub const InvalidBinaryRepresentation = "22P03"; // invalid_binary_representation
    pub const BadCopyFileFormat = "22P04"; // bad_copy_file_format
    pub const UnstranslatableCharacter = "22P05"; // untranslatable_character
    pub const NotAnXMLDocument = "2200L"; // not_an_xml_document
    pub const InvalideXMLDocument = "2200M"; // invalid_xml_document
    pub const InvalidXMLContent = "2200N"; // invalid_xml_content
    pub const InvalidXMLComment = "2200S"; // invalid_xml_comment
    pub const InvalidXMLProcessingInstruction = "2200T"; // invalid_xml_processing_instruction
    // // Class 23 — Integrity Constraint Violation
    pub const IntegrityConstraintViolation = "23000"; // integrity_constraint_violation
    pub const RestrictViolation = "23001"; // restrict_violation
    pub const NotNullViolation = "23502"; // not_null_violation
    pub const ForeignKeyViolation = "23503"; // foreign_key_violation
    pub const UniqueViolation = "23505"; // unique_violation
    pub const CheckViolation = "23514"; // check_violation
    pub const ExclusionViolation = "23P01"; // exclusion_violation
    // // Class 24 — Invalid Cursor State
    pub const InvalidCursorState = "24000"; // invalid_cursor_state
    // // Class 25 — Invalid Transaction State
    pub const InvalidTransactionState = "25000"; // invalid_transaction_state
    pub const ActiveSQLTransaction = "25001"; // active_sql_transaction
    pub const BranchTransactionAlreadyActive = "25002"; // branch_transaction_already_active
    pub const HeldCursorRequiresSameIsolationLevel = "25008"; // held_cursor_requires_same_isolation_level
    pub const InappropriateAccessModeForBranchTransaction = "25003"; // inappropriate_access_mode_for_branch_transaction
    pub const InappropriateIsolationLevelForBranchTransaction = "25004"; // inappropriate_isolation_level_for_branch_transaction
    pub const NoActiveSQLTransactionForBranchTransaction = "25005"; // no_active_sql_transaction_for_branch_transaction
    pub const ReadOnlySQLTransaction = "25006"; // read_only_sql_transaction
    pub const SchemaAndDataStatementMixingNotSupported = "25007"; // schema_and_data_statement_mixing_not_supported
    pub const NoActiveSQLTransaction = "25P01"; // no_active_sql_transaction
    pub const InFailedSQLTransaction = "25P02"; // in_failed_sql_transaction
    pub const IdleInTransactionSessionTimeout = "25P03"; // idle_in_transaction_session_timeout
    // Class 26 — Invalid SQL Statement Name
    pub const InvalidSQLStatementName = "26000"; // invalid_sql_statement_name
    // Class 27 — Triggered Data Change Violation
    pub const TriggeredDataChangeViolation = "27000"; // triggered_data_change_violation
    // Class 28 — Invalid Authorization Specification
    pub const InvalidAuthorizationSpecification = "28000"; // invalid_authorization_specification
    pub const InvalidPassword = "28P01"; // invalid_password
    // Class 2B — Dependent Privilege Descriptors Still Exist
    pub const DependentPrivilegeDescriptorsStillExist = "2B000"; // dependent_privilege_descriptors_still_exist
    pub const DependentObjectsStillExist = "2BP01"; // dependent_objects_still_exist
    // Class 2D — Invalid Transaction Termination
    pub const InvalidTransactionTermination = "2D000"; // invalid_transaction_termination
    // Class 2F — SQL Routine Exception
    pub const RoutineSQLRuntimeException = "2F000"; // sql_routine_exception
    pub const RoutineFunctionExecutedNoReturnStatement = "2F005"; // function_executed_no_return_statement
    pub const RoutineModifyingSQLDataNotPermitted = "2F002"; // modifying_sql_data_not_permitted
    pub const RoutineProhibitedSQLStatementAttempted = "2F003"; // prohibited_sql_statement_attempted
    pub const RoutineReadingSQLDataNotPermitted = "2F004"; // reading_sql_data_not_permitted
    // Class 34 — Invalid Cursor Name
    pub const InvalidCursorName = "34000"; // invalid_cursor_name
    // Class 38 — External Routine Exception
    pub const ExternalRoutineException = "38000"; // external_routine_exception
    pub const ExternalRoutineContainingSQLNotPermitted = "38001"; // containing_sql_not_permitted
    pub const ExternalRoutineModifyingSQLDataNotPermitted = "38002"; // modifying_sql_data_not_permitted
    pub const ExternalRoutineProhibitedSQLStatementAttempted = "38003"; // prohibited_sql_statement_attempted
    pub const ExternalRoutineReadingSQLDataNotPermitted = "38004"; // reading_sql_data_not_permitted
    // Class 39 — External Routine Invocation Exception
    pub const ExternalRoutineInvocationException = "39000"; // external_routine_invocation_exception
    pub const ExternalRoutineInvalidSQLStateReturned = "39001"; // invalid_sqlstate_returned
    pub const ExternalRoutineNullValueNotAllowed = "39004"; // null_value_not_allowed
    pub const ExternalRoutineTriggerProtocolViolated = "39P01"; // trigger_protocol_violated
    pub const ExternalRoutineSRFProtocolViolated = "39P02"; // srf_protocol_violated
    pub const ExternalRoutineEventTriggerProtocol = "39P03"; // event_trigger_protocol_violated
    // Class 3B — Savepoint Exception
    pub const SavepointException = "3B000"; // savepoint_exception
    pub const InvalidSavepointSpecification = "3B001"; // invalid_savepoint_specification
    // Class 3D — Invalid Catalog Name
    pub const InvalidCatalogName = "3D000"; // invalid_catalog_name
    // Class 3F — Invalid Schema Name
    pub const InvalidSchemaName = "3F000"; // invalid_schema_name
    // Class 40 — Transaction Rollback
    pub const TransactionRollback = "40000"; // transaction_rollback
    pub const TransactionIntegrityConstraintViolation = "40002"; // transaction_integrity_constraint_violation
    pub const SerializationFailure = "40001"; // serialization_failure
    pub const StatementCompletionUnknown = "40003"; // statement_completion_unknown
    pub const DeadlockDetected = "40P01"; // deadlock_detected
    // Class 42 — Syntax Error or Access Rule Violation
    pub const SyntaxErrorOrAccessRuleViolation = "42000"; // syntax_error_or_access_rule_violation
    pub const SyntaxError = "42601"; // syntax_error
    pub const InsufficientPrivilege = "42501"; // insufficient_privilege
    pub const CannotCoerce = "42846"; // cannot_coerce
    pub const GroupingError = "42803"; // grouping_error
    pub const WindowingError = "42P20"; // windowing_error
    pub const InvalidRecursion = "42P19"; // invalid_recursion
    pub const InvalidForeignKey = "42830"; // invalid_foreign_key
    pub const InvalidName = "42602"; // invalid_name
    pub const NameTooLong = "42622"; // name_too_long
    pub const ReservedName = "42939"; // reserved_name
    pub const DatatypeMismatch = "42804"; // datatype_mismatch
    pub const IndeterminateDatatype = "42P18"; // indeterminate_datatype
    pub const CollationMismatch = "42P21"; // collation_mismatch
    pub const IndeterminateCollation = "42P22"; // indeterminate_collation
    pub const WrongObjectType = "42809"; // wrong_object_type
    pub const UndefinedColumn = "42703"; // undefined_column
    pub const UndefinedFunction = "42883"; // undefined_function
    pub const UndefinedTable = "42P01"; // undefined_table
    pub const UndefinedParameter = "42P02"; // undefined_parameter
    pub const UndefinedObject = "42704"; // undefined_object
    pub const DuplicateColumn = "42701"; // duplicate_column
    pub const DuplicateCursor = "42P03"; // duplicate_cursor
    pub const DuplicateDatabase = "42P04"; // duplicate_database
    pub const DuplicateFunction = "42723"; // duplicate_function
    pub const DuplicatePreparedStatement = "42P05"; // duplicate_prepared_statement
    pub const DuplicateSchema = "42P06"; // duplicate_schema
    pub const DuplicateTable = "42P07"; // duplicate_table
    pub const DuplicateAlias = "42712"; // duplicate_alias
    pub const DuplicateObject = "42710"; // duplicate_object
    pub const AmbiguousColumn = "42702"; // ambiguous_column
    pub const AmbiguousFunction = "42725"; // ambiguous_function
    pub const AmbiguousParameter = "42P08"; // ambiguous_parameter
    pub const AmbiguousAlias = "42P09"; // ambiguous_alias
    pub const InvalidColumnReference = "42P10"; // invalid_column_reference
    pub const InvalidColumnDefinition = "42611"; // invalid_column_definition
    pub const InvalidCursorDefinition = "42P11"; // invalid_cursor_definition
    pub const InvalidDatabaseDefinition = "42P12"; // invalid_database_definition
    pub const InvalidFunctionDefinition = "42P13"; // invalid_function_definition
    pub const InvalidStatementDefinition = "42P14"; // invalid_prepared_statement_definition
    pub const InvalidSchemaDefinition = "42P15"; // invalid_schema_definition
    pub const InvalidTableDefinition = "42P16"; // invalid_table_definition
    pub const InvalidObjectDefinition = "42P17"; // invalid_object_definition
    // Class 44 — WITH CHECK OPTION Violation
    pub const WithCheckOptionViolation = "44000"; // with_check_option_violation
    // Class 53 — Insufficient Resources
    pub const InsufficientResources = "53000"; // insufficient_resources
    pub const DiskFull = "53100"; // disk_full
    pub const OutOfMemory = "53200"; // out_of_memory
    pub const TooManyConnections = "53300"; // too_many_connections
    pub const ConfigurationLimitExceeded = "53400"; // configuration_limit_exceeded
    // Class 54 — Program Limit Exceeded
    pub const ProgramLimitExceeded = "54000"; // program_limit_exceeded
    pub const StatementTooComplex = "54001"; // statement_too_complex
    pub const TooManyColumns = "54011"; // too_many_columns
    pub const TooManyArguments = "54023"; // too_many_arguments
    // Class 55 — Object Not In Prerequisite State
    pub const ObjectNotInPrerequisiteState = "55000"; // object_not_in_prerequisite_state
    pub const ObjectInUse = "55006"; // object_in_use
    pub const CantChangeRuntimeParam = "55P02"; // cant_change_runtime_param
    pub const LockNotAvailable = "55P03"; // lock_not_available
    // Class 57 — Operator Intervention
    pub const OperatorIntervention = "57000"; // operator_intervention
    pub const QueryCanceled = "57014"; // query_canceled
    pub const AdminShutdown = "57P01"; // admin_shutdown
    pub const CrashShutdown = "57P02"; // crash_shutdown
    pub const CannotConnectNow = "57P03"; // cannot_connect_now
    pub const DatabaseDropped = "57P04"; // database_dropped
    // Class 58 — System Error (errors external to PostgreSQL itself)
    pub const SystemError = "58000"; // system_error
    pub const IOError = "58030"; // io_error
    pub const UndefinedFile = "58P01"; // undefined_file
    pub const DuplicateFile = "58P02"; // duplicate_file
    // Class 72 — Snapshot Failure
    pub const SnapshotTooOld = "72000"; // snapshot_too_old
    // Class F0 — Configuration File Error
    pub const ConfigFileError = "F0000"; // config_file_error
    pub const LockFileExists = "F0001"; // lock_file_exists
    // Class HV — Foreign Data Wrapper Error (SQL/MED)
    pub const FDWError = "HV000"; // fdw_error
    pub const FDWColumnNameNotFound = "HV005"; // fdw_column_name_not_found
    pub const FDWDynamicParameterValueNeeded = "HV002"; // fdw_dynamic_parameter_value_needed
    pub const FDWFunctionSequenceError = "HV010"; // fdw_function_sequence_error
    pub const FDWInconsistentDescriptorInformation = "HV021"; // fdw_inconsistent_descriptor_information
    pub const FDWInvalidAttributeValue = "HV024"; // fdw_invalid_attribute_value
    pub const FDWInvalidColumnName = "HV007"; // fdw_invalid_column_name
    pub const FDWInvalidColumnNumber = "HV008"; // fdw_invalid_column_number
    pub const FDWInvalidDataType = "HV004"; // fdw_invalid_data_type
    pub const FDWInvalidDataTypeDescriptors = "HV006"; // fdw_invalid_data_type_descriptors
    pub const FDWInvalidDescriptorFieldIdentifier = "HV091"; // fdw_invalid_descriptor_field_identifier
    pub const FDWInvalidHandle = "HV00B"; // fdw_invalid_handle
    pub const FDWInvalidOptionIndex = "HV00C"; // fdw_invalid_option_index
    pub const FDWInvalidOptionName = "HV00D"; // fdw_invalid_option_name
    pub const FDWInvalidStringLengthOrBufferLength = "HV090"; // fdw_invalid_string_length_or_buffer_length
    pub const FDWInvalidStringFormat = "HV00A"; // fdw_invalid_string_format
    pub const FDWInvalidUseOfNullPointer = "HV009"; // fdw_invalid_use_of_null_pointer
    pub const FDWTooManyHandles = "HV014"; // fdw_too_many_handles
    pub const FDWOutOfMemory = "HV001"; // fdw_out_of_memory
    pub const FDWNoSchemas = "HV00P"; // fdw_no_schemas
    pub const FDWOptionNameNotFound = "HV00J"; // fdw_option_name_not_found
    pub const FDWReplyHandle = "HV00K"; // fdw_reply_handle
    pub const FDWSchemaNotFound = "HV00Q"; // fdw_schema_not_found
    pub const FDWTableNotFound = "HV00R"; // fdw_table_not_found
    pub const FDWUnableToCreateExecution = "HV00L"; // fdw_unable_to_create_execution
    pub const FDWUnableToCreateReply = "HV00M"; // fdw_unable_to_create_reply
    pub const FDWUnableToEstablishConnection = "HV00N"; // fdw_unable_to_establish_connection
    // Class P0 — PL/pgSQL Error
    pub const PLPGSQLError = "P0000"; // plpgsql_error
    pub const RaiseException = "P0001"; // raise_exception
    pub const NoDataFound = "P0002"; // no_data_found
    pub const TooManyRows = "P0003"; // too_many_rows
    pub const AssertFailure = "P0004"; // assert_failure
    // Class XX — Internal Error
    pub const InternalError = "XX000"; // internal_error
    pub const DataCorrupted = "XX001"; // data_corrupted
    pub const IndexCorrupted = "XX002"; // index_corrupted
};

// Writer wraps a Buffer and allows writing postgres wired values
pub const Writer = struct {
    buf: *std.Buffer,
    writer: io.BufferOutStream,

    pub fn init(buf: *std.Buffer) Writer {
        return Writer{
            .buf = buf,
            .writer = io.BufferOutStream.init(buf),
        };
    }

    pub fn writeByte(self: *Writer, b: u8) !void {
        try self.buf.appendByte(b);
    }

    pub fn write(self: *Writer, b: []const u8) !void {
        try self.buf.append(b);
    }

    pub fn writeString(self: *Writer, b: []const u8) !void {
        try self.buf.append(b);
        try self.buf.appendByte(0x00);
    }

    pub fn writeInt32(self: *Writer, b: i32) !void {
        var stream = &self.writer.stream;
        try stream.writeIntBig(u32, @intCast(u32, b));
    }

    pub fn writeInt16(self: *Writer, b: i16) !void {
        var stream = &self.writer.stream;
        try stream.writeIntBig(u16, @intCast(u16, b));
    }

    pub fn resetLength(self: *Writer, offset: Offset) void {
        var b = self.buf.toSlice();
        var s = b[@enumToInt(offset)..];
        var bytes: [(u32.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntBig(u32, &bytes, @intCast(u32, s.len));
        mem.copy(u8, s, bytes[0..]);
    }
};

pub const Error = struct {
    severity: []const u8,
    code: []const u8,
    message: []const u8,
    detail: ?[]const u8,
    hint: ?[]const u8,
    position: ?[]const u8,
    internal_position: ?[]const u8,
    where: ?[]const u8,
    schema_name: ?[]const u8,
    table_name: ?[]const u8,
    column_name: ?[]const u8,
    data_type_name: ?[]const u8,
    constraint: ?[]const u8,
    file: ?[]const u8,
    line: ?[]const u8,
    routine: ?[]const u8,

    pub fn getMessage(buf: *std.Buffer) !void {
        var w = &MessageWriter.init(buf);

        try w.writeByte(Type.ERROR_MESSAGE);
        try w.writeInt32(0);

        try w.writeByte(Field.SEVERITY);
        try w.writeString(self.severity);

        try w.writeByte(Field.CODE);
        try w.writeString(self.code);

        try w.writeByte(Field.MESSAGE);
        try w.writeString(self.message);

        if (self.detail) |detail| {
            try w.writeByte(Field.MESSAGE_DETAIL);
            try w.writeString(self.detail);
        }
        if (self.hint) |hint| {
            try w.writeByte(Field.MESSAGE_HINT);
            try w.writeString(self.hint);
        }
        try w.writeByte(0x00);
        try w.resetLength(.Base);
    }
};
