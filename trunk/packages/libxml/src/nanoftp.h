(*
 * Summary: minimal FTP implementation
 * Description: minimal FTP implementation allowing to fetch resources
 *              like external subset.
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: Daniel Veillard
 *)
 
#ifndef __NANO_FTP_H__
#define __NANO_FTP_H__

#include <libxml/xmlversion.h>

{ LIBXML_FTP_ENABLED

{ __cplusplus
extern "C" {
#endif

(**
 * ftpListCallback: 
 * @userData:  user provided data for the callback
 * @filename:  the file name (including "->" when links are shown)
 * @attrib:  the attribute string
 * @owner:  the owner string
 * @group:  the group string
 * @size:  the file size
 * @links:  the link count
 * @year:  the year
 * @month:  the month
 * @day:  the day
 * @hour:  the hour
 * @minute:  the minute
 *
 * A callback for the xmlNanoFTPList command.
 * Note that only one of year and day:minute are specified.
 *)
typedef void (*ftpListCallback) (void *userData,
	                         char *filename, char *attrib,
	                         char *owner, char *group,
				 unsigned long size, int links, int year,
				 char *month, int day, int hour,
				 int minute);
(**
 * ftpDataCallback: 
 * @userData: the user provided context
 * @data: the data received
 * @len: its size in bytes
 *
 * A callback for the xmlNanoFTPGet command.
 *)
typedef void (*ftpDataCallback) (void *userData,
				 char *data,
				 int len);

(*
 * Init
 *)
XMLPUBFUN void XMLCALL
	xmlNanoFTPInit		(void);
XMLPUBFUN void XMLCALL	
	xmlNanoFTPCleanup	(void);

(*
 * Creating/freeing contexts.
 *)
XMLPUBFUN void * XMLCALL	
	xmlNanoFTPNewCtxt	(char *URL);
XMLPUBFUN void XMLCALL	
	xmlNanoFTPFreeCtxt	(void * ctx);
XMLPUBFUN void * XMLCALL 	
	xmlNanoFTPConnectTo	(char *server,
				 int port);
(*
 * Opening/closing session connections.
 *)
XMLPUBFUN void * XMLCALL 	
	xmlNanoFTPOpen		(char *URL);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPConnect	(void *ctx);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPClose		(void *ctx);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPQuit		(void *ctx);
XMLPUBFUN void XMLCALL	
	xmlNanoFTPScanProxy	(char *URL);
XMLPUBFUN void XMLCALL	
	xmlNanoFTPProxy		(char *host,
				 int port,
				 char *user,
				 char *passwd,
				 int type);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPUpdateURL	(void *ctx,
				 char *URL);

(*
 * Rather internal commands.
 *)
XMLPUBFUN int XMLCALL	
	xmlNanoFTPGetResponse	(void *ctx);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPCheckResponse	(void *ctx);

(*
 * CD/DIR/GET handlers.
 *)
XMLPUBFUN int XMLCALL	
	xmlNanoFTPCwd		(void *ctx,
				 char *directory);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPDele		(void *ctx,
				 char *file);

XMLPUBFUN int XMLCALL	
	xmlNanoFTPGetConnection	(void *ctx);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPCloseConnection(void *ctx);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPList		(void *ctx,
				 ftpListCallback callback,
				 void *userData,
				 char *filename);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPGetSocket	(void *ctx,
				 char *filename);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPGet		(void *ctx,
				 ftpDataCallback callback,
				 void *userData,
				 char *filename);
XMLPUBFUN int XMLCALL	
	xmlNanoFTPRead		(void *ctx,
				 void *dest,
				 int len);

{ __cplusplus
}
#endif
#endif (* LIBXML_FTP_ENABLED *)
#endif (* __NANO_FTP_H__ *)
