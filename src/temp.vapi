[CCode (cprefix = "", cheader_filename = "config.h")]
namespace Config {
	[CCode (cname = "GETTEXT_PACKAGE")]
	public const string GETTEXT_PACKAGE;

	[CCode (cname = "DATA_DIRECTORY")]
	public const string DATA_DIRECTORY;

	[CCode (cname = "APPNAME_LONG")]
	public const string APPNAME_LONG;

	[CCode (cname = "VERSION")]
	public const string VERSION;

	[CCode (cname = "SOUND_DIRECTORY")]
	public const string SOUND_DIRECTORY;

	[CCode (cname = "LOCALEDIR")]
	public const string LOCALEDIR;
}
