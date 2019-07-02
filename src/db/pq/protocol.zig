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
