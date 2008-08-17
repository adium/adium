/* include/libgadu.h.  Generated from libgadu.h.in by configure.  */
/* $Id: libgadu.h.in,v 1.5.2.1 2007-04-21 23:44:25 wojtekka Exp $ */

/*
 *  (C) Copyright 2001-2003 Wojtek Kaniewski <wojtekka@irc.pl>
 *                          Robert J. Wo�ny <speedy@ziew.org>
 *                          Arkadiusz Mi�kiewicz <arekm@pld-linux.org>
 *                          Tomasz Chili�ski <chilek@chilan.com>
 *                          Piotr Wysocki <wysek@linux.bydg.org>
 *                          Dawid Jarosz <dawjar@poczta.onet.pl>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License Version
 *  2.1 as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307,
 *  USA.
 */

#ifndef __GG_LIBGADU_H
#define __GG_LIBGADU_H

#ifdef __cplusplus
#ifdef _WIN32
#pragma pack(push, 1)
#endif
extern "C" {
#endif

#include <sys/types.h>
#include <stdio.h>
#include <stdarg.h>

/* Defined if libgadu was compiled for bigendian machine. */
/* #undef GG_CONFIG_BIGENDIAN */

/* Defined if this machine has gethostbyname_r(). */
/* #undef GG_CONFIG_HAVE_GETHOSTBYNAME_R */

/* Defined if libgadu was compiled and linked with pthread support. */
/* #undef GG_CONFIG_HAVE_PTHREAD */

/* Defined if this machine has C99-compiliant vsnprintf(). */
#define GG_CONFIG_HAVE_C99_VSNPRINTF 

/* Defined if this machine has va_copy(). */
#define GG_CONFIG_HAVE_VA_COPY 

/* Defined if this machine has __va_copy(). */
#define GG_CONFIG_HAVE___VA_COPY 

/* Defined if this machine supports long long. */
#define GG_CONFIG_HAVE_LONG_LONG 

/* Defined if libgadu was compiled and linked with TLS support. */
#define GG_CONFIG_HAVE_OPENSSL 

/* Defined if uintX_t types are defined in <stdint.h>. */
#define GG_CONFIG_HAVE_STDINT_H 

/* Defined if uintX_t types are defined in <inttypes.h>. */
/* #undef GG_CONFIG_HAVE_INTTYPES_H */

/* Defined if uintX_t types are defined in <sys/inttypes.h>. */
/* #undef GG_CONFIG_HAVE_SYS_INTTYPES_H */

/* Defined if uintX_t types are defined in <sys/int_types.h>. */
/* #undef GG_CONFIG_HAVE_SYS_INT_TYPES_H */

/* Defined if uintX_t types are defined in <sys/types.h>. */
/* #undef GG_CONFIG_HAVE_SYS_TYPES_H */

#ifdef GG_CONFIG_HAVE_OPENSSL
#include <openssl/ssl.h>
#endif

#ifdef GG_CONFIG_HAVE_STDINT_H
#include <stdint.h>
#else
#  ifdef GG_CONFIG_HAVE_INTTYPES_H
#  include <inttypes.h>
#  else
#    ifdef GG_CONFIG_HAVE_SYS_INTTYPES_H
#    include <sys/inttypes.h>
#    else
#      ifdef GG_CONFIG_HAVE_SYS_INT_TYPES_H
#      include <sys/int_types.h>
#      else
#        ifdef GG_CONFIG_HAVE_SYS_TYPES_H
#        include <sys/types.h>
#        else

#ifndef __AC_STDINT_H
#define __AC_STDINT_H

/* ISO C 9X: 7.18 Integer types <stdint.h> */

typedef unsigned char   uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;

#ifndef __CYGWIN__
#define __int8_t_defined
typedef   signed char    int8_t;
typedef   signed short  int16_t;
typedef   signed int    int32_t;
#endif

#endif /* __AC_STDINT_H */

#        endif
#      endif
#    endif
#  endif
#endif

/*
 * typedef uin_t
 *
 * typ reprezentuj�cy numer osoby.
 */
typedef uint32_t uin_t;

/*
 * og�lna struktura opisuj�ca r�ne sesje. przydatna w klientach.
 */
#define gg_common_head(x) \
	int fd;			/* podgl�dany deskryptor */ \
	int check;		/* sprawdzamy zapis czy odczyt */ \
	int state;		/* aktualny stan maszynki */ \
	int error;		/* kod b��du dla GG_STATE_ERROR */ \
	int type;		/* rodzaj sesji */ \
	int id;			/* identyfikator */ \
	int timeout;		/* sugerowany timeout w sekundach */ \
	int (*callback)(x*); 	/* callback przy zmianach */ \
	void (*destroy)(x*); 	/* funkcja niszczenia */

struct gg_common {
	gg_common_head(struct gg_common)
};

struct gg_image_queue;

/*
 * struct gg_session
 *
 * struktura opisuj�ca dan� sesj�. tworzona przez gg_login(), zwalniana
 * przez gg_free_session().
 */
struct gg_session {
	gg_common_head(struct gg_session)

	int async;      	/* czy po��czenie jest asynchroniczne */
	int pid;        	/* pid procesu resolvera */
	int port;       	/* port, z kt�rym si� ��czymy */
	int seq;        	/* numer sekwencyjny ostatniej wiadomo�ci */
	int last_pong;  	/* czas otrzymania ostatniego ping/pong */
	int last_event;		/* czas otrzymania ostatniego pakietu */

	struct gg_event *event;	/* zdarzenie po ->callback() */

	uint32_t proxy_addr;	/* adres proxy, keszowany */
	uint16_t proxy_port;	/* port proxy */

	uint32_t hub_addr;	/* adres huba po resolvni�ciu */
	uint32_t server_addr;	/* adres serwera, od huba */

	uint32_t client_addr;	/* adres klienta */
	uint16_t client_port;	/* port, na kt�rym klient s�ucha */

	uint32_t external_addr;	/* adres zewnetrzny klienta */
	uint16_t external_port;	/* port zewnetrzny klienta */

	uin_t uin;		/* numerek klienta */
	char *password;		/* i jego has�o. zwalniane automagicznie */

	int initial_status;	/* pocz�tkowy stan klienta */
	int status;		/* aktualny stan klienta */

	char *recv_buf;		/* bufor na otrzymywane pakiety */
	int recv_done;		/* ile ju� wczytano do bufora */
	int recv_left;		/* i ile jeszcze trzeba wczyta� */

	int protocol_version;	/* wersja u�ywanego protoko�u */
	char *client_version;	/* wersja u�ywanego klienta */
	int last_sysmsg;	/* ostatnia wiadomo�� systemowa */

	char *initial_descr;	/* pocz�tkowy opis stanu klienta */

	void *resolver;		/* wska�nik na informacje resolvera */

	char *header_buf;	/* bufor na pocz�tek nag��wka */
	unsigned int header_done;/* ile ju� mamy */

#ifdef GG_CONFIG_HAVE_OPENSSL
	SSL *ssl;		/* sesja TLS */
	SSL_CTX *ssl_ctx;	/* kontekst sesji? */
#else
	void *ssl;		/* zachowujemy ABI */
	void *ssl_ctx;
#endif

	int image_size;		/* maksymalny rozmiar obrazk�w w KiB */

	char *userlist_reply;	/* fragment odpowiedzi listy kontakt�w */

	int userlist_blocks;	/* na ile kawa�k�w podzielono list� kontakt�w */

	struct gg_image_queue *images;	/* aktualnie wczytywane obrazki */
};

/*
 * struct gg_http
 *
 * og�lna struktura opisuj�ca stan wszystkich operacji HTTP. tworzona
 * przez gg_http_connect(), zwalniana przez gg_http_free().
 */
struct gg_http {
	gg_common_head(struct gg_http)

	int async;              /* czy po��czenie asynchroniczne */
	int pid;                /* pid procesu resolvera */
	int port;               /* port, z kt�rym si� ��czymy */

	char *query;            /* bufor zapytania http */
	char *header;           /* bufor nag��wka */
	int header_size;        /* rozmiar wczytanego nag��wka */
	char *body;             /* bufor otrzymanych informacji */
	unsigned int body_size; /* oczekiwana ilo�� informacji */

	void *data;             /* dane danej operacji http */

	char *user_data;	/* dane u�ytkownika, nie s� zwalniane przez gg_http_free() */

	void *resolver;		/* wska�nik na informacje resolvera */

	unsigned int body_done;	/* ile ju� tre�ci odebrano? */
};

#ifdef __GNUC__
#define GG_PACKED __attribute__ ((packed))
#else
#define GG_PACKED
#endif

#define GG_MAX_PATH 276

/*
 * struct gg_file_info
 *
 * odpowiednik windowsowej struktury WIN32_FIND_DATA niezb�dnej przy
 * wysy�aniu plik�w.
 */
struct gg_file_info {
	uint32_t mode;			/* dwFileAttributes */
	uint32_t ctime[2];		/* ftCreationTime */
	uint32_t atime[2];		/* ftLastAccessTime */
	uint32_t mtime[2];		/* ftLastWriteTime */
	uint32_t size_hi;		/* nFileSizeHigh */
	uint32_t size;			/* nFileSizeLow */
	uint32_t reserved0;		/* dwReserved0 */
	uint32_t reserved1;		/* dwReserved1 */
	unsigned char filename[GG_MAX_PATH - 14];	/* cFileName */
	unsigned char short_filename[14];		/* cAlternateFileName */
} GG_PACKED;

/*
 * struct gg_dcc
 *
 * struktura opisuj�ca nas�uchuj�ce gniazdo po��cze� mi�dzy klientami.
 * tworzona przez gg_dcc_socket_create(), zwalniana przez gg_dcc_free().
 */
struct gg_dcc {
	gg_common_head(struct gg_dcc)

	struct gg_event *event;	/* opis zdarzenia */

	int active;		/* czy to my si� ��czymy? */
	int port;		/* port, na kt�rym siedzi */
	uin_t uin;		/* uin klienta */
	uin_t peer_uin;		/* uin drugiej strony */
	int file_fd;		/* deskryptor pliku */
	unsigned int offset;	/* offset w pliku */
	unsigned int chunk_size;/* rozmiar kawa�ka */
	unsigned int chunk_offset;/* offset w aktualnym kawa�ku */
	struct gg_file_info file_info;
				/* informacje o pliku */
	int established;	/* po��czenie ustanowione */
	char *voice_buf;	/* bufor na pakiet po��czenia g�osowego */
	int incoming;		/* po��czenie przychodz�ce */
	char *chunk_buf;	/* bufor na kawa�ek danych */
	uint32_t remote_addr;	/* adres drugiej strony */
	uint16_t remote_port;	/* port drugiej strony */
};

/*
 * enum gg_session_t
 *
 * rodzaje sesji.
 */
enum gg_session_t {
	GG_SESSION_GG = 1,	/* po��czenie z serwerem gg */
	GG_SESSION_HTTP,	/* og�lna sesja http */
	GG_SESSION_SEARCH,	/* szukanie */
	GG_SESSION_REGISTER,	/* rejestrowanie */
	GG_SESSION_REMIND,	/* przypominanie has�a */
	GG_SESSION_PASSWD,	/* zmiana has�a */
	GG_SESSION_CHANGE,	/* zmiana informacji o sobie */
	GG_SESSION_DCC,		/* og�lne po��czenie DCC */
	GG_SESSION_DCC_SOCKET,	/* nas�uchuj�cy socket */
	GG_SESSION_DCC_SEND,	/* wysy�anie pliku */
	GG_SESSION_DCC_GET,	/* odbieranie pliku */
	GG_SESSION_DCC_VOICE,	/* rozmowa g�osowa */
	GG_SESSION_USERLIST_GET,	/* pobieranie userlisty */
	GG_SESSION_USERLIST_PUT,	/* wysy�anie userlisty */
	GG_SESSION_UNREGISTER,	/* usuwanie konta */
	GG_SESSION_USERLIST_REMOVE,	/* usuwanie userlisty */
	GG_SESSION_TOKEN,	/* pobieranie tokenu */

	GG_SESSION_USER0 = 256,	/* zdefiniowana dla u�ytkownika */
	GG_SESSION_USER1,	/* j.w. */
	GG_SESSION_USER2,	/* j.w. */
	GG_SESSION_USER3,	/* j.w. */
	GG_SESSION_USER4,	/* j.w. */
	GG_SESSION_USER5,	/* j.w. */
	GG_SESSION_USER6,	/* j.w. */
	GG_SESSION_USER7	/* j.w. */
};

/*
 * enum gg_state_t
 *
 * opisuje stan asynchronicznej maszyny.
 */
enum gg_state_t {
		/* wsp�lne */
	GG_STATE_IDLE = 0,		/* nie powinno wyst�pi�. */
	GG_STATE_RESOLVING,             /* wywo�a� gethostbyname() */
	GG_STATE_CONNECTING,            /* wywo�a� connect() */
	GG_STATE_READING_DATA,		/* czeka na dane http */
	GG_STATE_ERROR,			/* wyst�pi� b��d. kod w x->error */

		/* gg_session */
	GG_STATE_CONNECTING_HUB,	/* wywo�a� connect() na huba */
	GG_STATE_CONNECTING_GG,         /* wywo�a� connect() na serwer */
	GG_STATE_READING_KEY,           /* czeka na klucz */
	GG_STATE_READING_REPLY,         /* czeka na odpowied� */
	GG_STATE_CONNECTED,             /* po��czy� si� */

		/* gg_http */
	GG_STATE_SENDING_QUERY,		/* wysy�a zapytanie http */
	GG_STATE_READING_HEADER,	/* czeka na nag��wek http */
	GG_STATE_PARSING,               /* przetwarza dane */
	GG_STATE_DONE,                  /* sko�czy� */

		/* gg_dcc */
	GG_STATE_LISTENING,		/* czeka na po��czenia */
	GG_STATE_READING_UIN_1,		/* czeka na uin peera */
	GG_STATE_READING_UIN_2,		/* czeka na sw�j uin */
	GG_STATE_SENDING_ACK,		/* wysy�a potwierdzenie dcc */
	GG_STATE_READING_ACK,		/* czeka na potwierdzenie dcc */
	GG_STATE_READING_REQUEST,	/* czeka na komend� */
	GG_STATE_SENDING_REQUEST,	/* wysy�a komend� */
	GG_STATE_SENDING_FILE_INFO,	/* wysy�a informacje o pliku */
	GG_STATE_READING_PRE_FILE_INFO,	/* czeka na pakiet przed file_info */
	GG_STATE_READING_FILE_INFO,	/* czeka na informacje o pliku */
	GG_STATE_SENDING_FILE_ACK,	/* wysy�a potwierdzenie pliku */
	GG_STATE_READING_FILE_ACK,	/* czeka na potwierdzenie pliku */
	GG_STATE_SENDING_FILE_HEADER,	/* wysy�a nag��wek pliku */
	GG_STATE_READING_FILE_HEADER,	/* czeka na nag��wek */
	GG_STATE_GETTING_FILE,		/* odbiera plik */
	GG_STATE_SENDING_FILE,		/* wysy�a plik */
	GG_STATE_READING_VOICE_ACK,	/* czeka na potwierdzenie voip */
	GG_STATE_READING_VOICE_HEADER,	/* czeka na rodzaj bloku voip */
	GG_STATE_READING_VOICE_SIZE,	/* czeka na rozmiar bloku voip */
	GG_STATE_READING_VOICE_DATA,	/* czeka na dane voip */
	GG_STATE_SENDING_VOICE_ACK,	/* wysy�a potwierdzenie voip */
	GG_STATE_SENDING_VOICE_REQUEST,	/* wysy�a ��danie voip */
	GG_STATE_READING_TYPE,		/* czeka na typ po��czenia */

	/* nowe. bez sensu jest to API. */
	GG_STATE_TLS_NEGOTIATION	/* negocjuje po��czenie TLS */
};

/*
 * enum gg_check_t
 *
 * informuje, co proces klienta powinien sprawdzi� na deskryptorze danego
 * po��czenia.
 */
enum gg_check_t {
	GG_CHECK_NONE = 0,		/* nic. nie powinno wyst�pi� */
	GG_CHECK_WRITE = 1,		/* sprawdzamy mo�liwo�� zapisu */
	GG_CHECK_READ = 2		/* sprawdzamy mo�liwo�� odczytu */
};

/*
 * struct gg_login_params
 *
 * parametry gg_login(). przeniesiono do struktury, �eby unikn�� problem�w
 * z ci�g�ymi zmianami API, gdy dodano co� nowego do protoko�u.
 */
struct gg_login_params {
	uin_t uin;			/* numerek */
	char *password;			/* has�o */
	int async;			/* asynchroniczne sockety? */
	int status;			/* pocz�tkowy status klienta */
	char *status_descr;		/* opis statusu */
	uint32_t server_addr;		/* adres serwera gg */
	uint16_t server_port;		/* port serwera gg */
	uint32_t client_addr;		/* adres dcc klienta */
	uint16_t client_port;		/* port dcc klienta */
	int protocol_version;		/* wersja protoko�u */
	char *client_version;		/* wersja klienta */
	int has_audio;			/* czy ma d�wi�k? */
	int last_sysmsg;		/* ostatnia wiadomo�� systemowa */
	uint32_t external_addr;		/* adres widziany na zewnatrz */
	uint16_t external_port;		/* port widziany na zewnatrz */
	int tls;			/* czy ��czymy po TLS? */
	int image_size;			/* maksymalny rozmiar obrazka w KiB */
	int era_omnix;			/* czy udawa� klienta era omnix? */

	char dummy[6 * sizeof(int)];	/* miejsce na kolejnych 6 zmiennych,
					 * �eby z dodaniem parametru nie
					 * zmienia� si� rozmiar struktury */
};

struct gg_session *gg_login(const struct gg_login_params *p);
void gg_free_session(struct gg_session *sess);
void gg_logoff(struct gg_session *sess);
int gg_change_status(struct gg_session *sess, int status);
int gg_change_status_descr(struct gg_session *sess, int status, const char *descr);
int gg_change_status_descr_time(struct gg_session *sess, int status, const char *descr, int time);
int gg_send_message(struct gg_session *sess, int msgclass, uin_t recipient, const unsigned char *message);
int gg_send_message_richtext(struct gg_session *sess, int msgclass, uin_t recipient, const unsigned char *message, const unsigned char *format, int formatlen);
int gg_send_message_confer(struct gg_session *sess, int msgclass, int recipients_count, uin_t *recipients, const unsigned char *message);
int gg_send_message_confer_richtext(struct gg_session *sess, int msgclass, int recipients_count, uin_t *recipients, const unsigned char *message, const unsigned char *format, int formatlen);
int gg_send_message_ctcp(struct gg_session *sess, int msgclass, uin_t recipient, const unsigned char *message, int message_len);
int gg_ping(struct gg_session *sess);
int gg_userlist_request(struct gg_session *sess, char type, const char *request);
int gg_image_request(struct gg_session *sess, uin_t recipient, int size, uint32_t crc32);
int gg_image_reply(struct gg_session *sess, uin_t recipient, const char *filename, const char *image, int size);

uint32_t gg_crc32(uint32_t crc, const unsigned char *buf, int len);

struct gg_image_queue {
	uin_t sender;			/* nadawca obrazka */
	uint32_t size;			/* rozmiar */
	uint32_t crc32;			/* suma kontrolna */
	char *filename;			/* nazwa pliku */
	char *image;			/* bufor z obrazem */
	uint32_t done;			/* ile ju� wczytano */

	struct gg_image_queue *next;	/* nast�pny na li�cie */
};

/*
 * enum gg_event_t
 *
 * rodzaje zdarze�.
 */
enum gg_event_t {
	GG_EVENT_NONE = 0,		/* nic si� nie wydarzy�o */
	GG_EVENT_MSG,			/* otrzymano wiadomo�� */
	GG_EVENT_NOTIFY,		/* kto� si� pojawi� */
	GG_EVENT_NOTIFY_DESCR,		/* kto� si� pojawi� z opisem */
	GG_EVENT_STATUS,		/* kto� zmieni� stan */
	GG_EVENT_ACK,			/* potwierdzenie wys�ania wiadomo�ci */
	GG_EVENT_PONG,			/* pakiet pong */
	GG_EVENT_CONN_FAILED,		/* po��czenie si� nie uda�o */
	GG_EVENT_CONN_SUCCESS,		/* po��czenie si� powiod�o */
	GG_EVENT_DISCONNECT,		/* serwer zrywa po��czenie */

	GG_EVENT_DCC_NEW,		/* nowe po��czenie mi�dzy klientami */
	GG_EVENT_DCC_ERROR,		/* b��d po��czenia mi�dzy klientami */
	GG_EVENT_DCC_DONE,		/* zako�czono po��czenie */
	GG_EVENT_DCC_CLIENT_ACCEPT,	/* moment akceptacji klienta */
	GG_EVENT_DCC_CALLBACK,		/* klient si� po��czy� na ��danie */
	GG_EVENT_DCC_NEED_FILE_INFO,	/* nale�y wype�ni� file_info */
	GG_EVENT_DCC_NEED_FILE_ACK,	/* czeka na potwierdzenie pliku */
	GG_EVENT_DCC_NEED_VOICE_ACK,	/* czeka na potwierdzenie rozmowy */
	GG_EVENT_DCC_VOICE_DATA, 	/* ramka danych rozmowy g�osowej */

	GG_EVENT_PUBDIR50_SEARCH_REPLY,	/* odpowiedz wyszukiwania */
	GG_EVENT_PUBDIR50_READ,		/* odczytano w�asne dane z katalogu */
	GG_EVENT_PUBDIR50_WRITE,	/* wpisano w�asne dane do katalogu */

	GG_EVENT_STATUS60,		/* kto� zmieni� stan w GG 6.0 */
	GG_EVENT_NOTIFY60,		/* kto� si� pojawi� w GG 6.0 */
	GG_EVENT_USERLIST,		/* odpowied� listy kontakt�w w GG 6.0 */
	GG_EVENT_IMAGE_REQUEST,		/* pro�ba o wys�anie obrazka GG 6.0 */
	GG_EVENT_IMAGE_REPLY,		/* podes�any obrazek GG 6.0 */
	GG_EVENT_DCC_ACK		/* potwierdzenie transmisji */
};

#define GG_EVENT_SEARCH50_REPLY GG_EVENT_PUBDIR50_SEARCH_REPLY

/*
 * enum gg_failure_t
 *
 * okre�la pow�d nieudanego po��czenia.
 */
enum gg_failure_t {
	GG_FAILURE_RESOLVING = 1,	/* nie znaleziono serwera */
	GG_FAILURE_CONNECTING,		/* nie mo�na si� po��czy� */
	GG_FAILURE_INVALID,		/* serwer zwr�ci� nieprawid�owe dane */
	GG_FAILURE_READING,		/* zerwano po��czenie podczas odczytu */
	GG_FAILURE_WRITING,		/* zerwano po��czenie podczas zapisu */
	GG_FAILURE_PASSWORD,		/* nieprawid�owe has�o */
	GG_FAILURE_404, 		/* XXX nieu�ywane */
	GG_FAILURE_TLS,			/* b��d negocjacji TLS */
	GG_FAILURE_NEED_EMAIL, 		/* serwer roz��czy� nas z pro�b� o zmian� emaila */
	GG_FAILURE_INTRUDER,		/* za du�o pr�b po��czenia si� z nieprawid�owym has�em */
	GG_FAILURE_UNAVAILABLE		/* serwery s� wy��czone */
};

/*
 * enum gg_error_t
 *
 * okre�la rodzaj b��du wywo�anego przez dan� operacj�. nie zawiera
 * przesadnie szczeg�owych informacji o powodzie b��du, by nie komplikowa�
 * obs�ugi b��d�w. je�li wymagana jest wi�ksza dok�adno��, nale�y sprawdzi�
 * zawarto�� zmiennej errno.
 */
enum gg_error_t {
	GG_ERROR_RESOLVING = 1,		/* b��d znajdowania hosta */
	GG_ERROR_CONNECTING,		/* b��d �aczenia si� */
	GG_ERROR_READING,		/* b��d odczytu */
	GG_ERROR_WRITING,		/* b��d wysy�ania */

	GG_ERROR_DCC_HANDSHAKE,		/* b��d negocjacji */
	GG_ERROR_DCC_FILE,		/* b��d odczytu/zapisu pliku */
	GG_ERROR_DCC_EOF,		/* plik si� sko�czy�? */
	GG_ERROR_DCC_NET,		/* b��d wysy�ania/odbierania */
	GG_ERROR_DCC_REFUSED 		/* po��czenie odrzucone przez usera */
};

/*
 * struktury dotycz�ce wyszukiwania w GG 5.0. NIE NALE�Y SI� DO NICH
 * ODWO�YWA� BEZPO�REDNIO! do dost�pu do nich s�u�� funkcje gg_pubdir50_*()
 */
struct gg_pubdir50_entry {
	int num;
	char *field;
	char *value;
};

struct gg_pubdir50_s {
	int count;
	uin_t next;
	int type;
	uint32_t seq;
	struct gg_pubdir50_entry *entries;
	int entries_count;
};

/*
 * typedef gg_pubdir_50_t
 *
 * typ opisuj�cy zapytanie lub wynik zapytania katalogu publicznego
 * z protoko�u GG 5.0. nie nale�y si� odwo�ywa� bezpo�rednio do jego
 * p�l -- s�u�� do tego funkcje gg_pubdir50_*()
 */
typedef struct gg_pubdir50_s *gg_pubdir50_t;

/*
 * struct gg_event
 *
 * struktura opisuj�ca rodzaj zdarzenia. wychodzi z gg_watch_fd() lub
 * z gg_dcc_watch_fd()
 */
struct gg_event {
	int type;	/* rodzaj zdarzenia -- gg_event_t */
	union {		/* @event */
		struct gg_notify_reply *notify;	/* informacje o li�cie kontakt�w -- GG_EVENT_NOTIFY */

		enum gg_failure_t failure;	/* b��d po��czenia -- GG_EVENT_FAILURE */

		struct gg_dcc *dcc_new;		/* nowe po��czenie bezpo�rednie -- GG_EVENT_DCC_NEW */

		int dcc_error;			/* b��d po��czenia bezpo�redniego -- GG_EVENT_DCC_ERROR */

		gg_pubdir50_t pubdir50;		/* wynik operacji zwi�zanej z katalogiem publicznym -- GG_EVENT_PUBDIR50_* */

		struct {			/* @msg odebrano wiadomo�� -- GG_EVENT_MSG */
			uin_t sender;		/* numer nadawcy */
			int msgclass;		/* klasa wiadomo�ci */
			time_t time;		/* czas nadania */
			unsigned char *message;	/* tre�� wiadomo�ci */

			int recipients_count;	/* ilo�� odbiorc�w konferencji */
			uin_t *recipients;	/* odbiorcy konferencji */

			int formats_length;	/* d�ugo�� informacji o formatowaniu tekstu */
			void *formats;		/* informacje o formatowaniu tekstu */
		} msg;

		struct {			/* @notify_descr informacje o li�cie kontakt�w z opisami stanu -- GG_EVENT_NOTIFY_DESCR */
			struct gg_notify_reply *notify;	/* informacje o li�cie kontakt�w */
			char *descr;		/* opis stanu */
		} notify_descr;

		struct {			/* @status zmiana stanu -- GG_EVENT_STATUS */
			uin_t uin;		/* numer */
			uint32_t status;	/* nowy stan */
			char *descr;		/* opis stanu */
		} status;

		struct {			/* @status60 zmiana stanu -- GG_EVENT_STATUS60 */
			uin_t uin;		/* numer */
			int status;	/* nowy stan */
			uint32_t remote_ip;	/* adres ip */
			uint16_t remote_port;	/* port */
			int version;	/* wersja klienta */
			int image_size;	/* maksymalny rozmiar grafiki w KiB */
			char *descr;		/* opis stanu */
			time_t time;		/* czas powrotu */
		} status60;

		struct {			/* @notify60 informacja o li�cie kontakt�w -- GG_EVENT_NOTIFY60 */
			uin_t uin;		/* numer */
			int status;	/* stan */
			uint32_t remote_ip;	/* adres ip */
			uint16_t remote_port;	/* port */
			int version;	/* wersja klienta */
			int image_size;	/* maksymalny rozmiar grafiki w KiB */
			char *descr;		/* opis stanu */
			time_t time;		/* czas powrotu */
		} *notify60;

		struct {			/* @ack potwierdzenie wiadomo�ci -- GG_EVENT_ACK */
			uin_t recipient;	/* numer odbiorcy */
			int status;		/* stan dor�czenia wiadomo�ci */
			int seq;		/* numer sekwencyjny wiadomo�ci */
		} ack;

		struct {			/* @dcc_voice_data otrzymano dane d�wi�kowe -- GG_EVENT_DCC_VOICE_DATA */
			uint8_t *data;		/* dane d�wi�kowe */
			int length;		/* ilo�� danych d�wi�kowych */
		} dcc_voice_data;

		struct {			/* @userlist odpowied� listy kontakt�w serwera */
			char type;		/* rodzaj odpowiedzi */
			char *reply;		/* tre�� odpowiedzi */
		} userlist;

		struct {			/* @image_request pro�ba o obrazek */
			uin_t sender;		/* nadawca pro�by */
			uint32_t size;		/* rozmiar obrazka */
			uint32_t crc32;		/* suma kontrolna */
		} image_request;

		struct {			/* @image_reply odpowied� z obrazkiem */
			uin_t sender;		/* nadawca odpowiedzi */
			uint32_t size;		/* rozmiar obrazka */
			uint32_t crc32;		/* suma kontrolna */
			char *filename;		/* nazwa pliku */
			char *image;		/* bufor z obrazkiem */
		} image_reply;
	} event;
};

struct gg_event *gg_watch_fd(struct gg_session *sess);
void gg_event_free(struct gg_event *e);
#define gg_free_event gg_event_free

/*
 * funkcje obs�ugi listy kontakt�w.
 */
int gg_notify_ex(struct gg_session *sess, uin_t *userlist, char *types, int count);
int gg_notify(struct gg_session *sess, uin_t *userlist, int count);
int gg_add_notify_ex(struct gg_session *sess, uin_t uin, char type);
int gg_add_notify(struct gg_session *sess, uin_t uin);
int gg_remove_notify_ex(struct gg_session *sess, uin_t uin, char type);
int gg_remove_notify(struct gg_session *sess, uin_t uin);

/*
 * funkcje obs�ugi http.
 */
struct gg_http *gg_http_connect(const char *hostname, int port, int async, const char *method, const char *path, const char *header);
int gg_http_watch_fd(struct gg_http *h);
void gg_http_stop(struct gg_http *h);
void gg_http_free(struct gg_http *h);
void gg_http_free_fields(struct gg_http *h);
#define gg_free_http gg_http_free

/*
 * struktury opisuj�ca kryteria wyszukiwania dla gg_search(). nieaktualne,
 * zast�pione przez gg_pubdir50_t. pozostawiono je dla zachowania ABI.
 */
struct gg_search_request {
	int active;
	unsigned int start;
	char *nickname;
	char *first_name;
	char *last_name;
	char *city;
	int gender;
	int min_birth;
	int max_birth;
	char *email;
	char *phone;
	uin_t uin;
};

struct gg_search {
	int count;
	struct gg_search_result *results;
};

struct gg_search_result {
	uin_t uin;
	char *first_name;
	char *last_name;
	char *nickname;
	int born;
	int gender;
	char *city;
	int active;
};

#define GG_GENDER_NONE 0
#define GG_GENDER_FEMALE 1
#define GG_GENDER_MALE 2

/*
 * funkcje wyszukiwania.
 */
struct gg_http *gg_search(const struct gg_search_request *r, int async);
int gg_search_watch_fd(struct gg_http *f);
void gg_free_search(struct gg_http *f);
#define gg_search_free gg_free_search

const struct gg_search_request *gg_search_request_mode_0(char *nickname, char *first_name, char *last_name, char *city, int gender, int min_birth, int max_birth, int active, int start);
const struct gg_search_request *gg_search_request_mode_1(char *email, int active, int start);
const struct gg_search_request *gg_search_request_mode_2(char *phone, int active, int start);
const struct gg_search_request *gg_search_request_mode_3(uin_t uin, int active, int start);
void gg_search_request_free(struct gg_search_request *r);

/*
 * funkcje obs�ugi katalogu publicznego zgodne z GG 5.0. tym razem funkcje
 * zachowuj� pewien poziom abstrakcji, �eby unikn�� zmian ABI przy zmianach
 * w protokole.
 *
 * NIE NALE�Y SI� ODWO�YWA� DO P�L gg_pubdir50_t BEZPO�REDNIO!
 */
uint32_t gg_pubdir50(struct gg_session *sess, gg_pubdir50_t req);
gg_pubdir50_t gg_pubdir50_new(int type);
int gg_pubdir50_add(gg_pubdir50_t req, const char *field, const char *value);
int gg_pubdir50_seq_set(gg_pubdir50_t req, uint32_t seq);
const char *gg_pubdir50_get(gg_pubdir50_t res, int num, const char *field);
int gg_pubdir50_type(gg_pubdir50_t res);
int gg_pubdir50_count(gg_pubdir50_t res);
uin_t gg_pubdir50_next(gg_pubdir50_t res);
uint32_t gg_pubdir50_seq(gg_pubdir50_t res);
void gg_pubdir50_free(gg_pubdir50_t res);

#define GG_PUBDIR50_UIN "FmNumber"
#define GG_PUBDIR50_STATUS "FmStatus"
#define GG_PUBDIR50_FIRSTNAME "firstname"
#define GG_PUBDIR50_LASTNAME "lastname"
#define GG_PUBDIR50_NICKNAME "nickname"
#define GG_PUBDIR50_BIRTHYEAR "birthyear"
#define GG_PUBDIR50_CITY "city"
#define GG_PUBDIR50_GENDER "gender"
#define GG_PUBDIR50_GENDER_FEMALE "1"
#define GG_PUBDIR50_GENDER_MALE "2"
#define GG_PUBDIR50_GENDER_SET_FEMALE "2"
#define GG_PUBDIR50_GENDER_SET_MALE "1"
#define GG_PUBDIR50_ACTIVE "ActiveOnly"
#define GG_PUBDIR50_ACTIVE_TRUE "1"
#define GG_PUBDIR50_START "fmstart"
#define GG_PUBDIR50_FAMILYNAME "familyname"
#define GG_PUBDIR50_FAMILYCITY "familycity"

int gg_pubdir50_handle_reply(struct gg_event *e, const char *packet, int length);

/*
 * struct gg_pubdir
 *
 * operacje na katalogu publicznym.
 */
struct gg_pubdir {
	int success;		/* czy si� uda�o */
	uin_t uin;		/* otrzymany numerek. 0 je�li b��d */
};

/* og�lne funkcje, nie powinny by� u�ywane */
int gg_pubdir_watch_fd(struct gg_http *f);
void gg_pubdir_free(struct gg_http *f);
#define gg_free_pubdir gg_pubdir_free

struct gg_token {
	int width;		/* szeroko�� obrazka */
	int height;		/* wysoko�� obrazka */
	int length;		/* ilo�� znak�w w tokenie */
	char *tokenid;		/* id tokenu */
};

/* funkcje dotycz�ce token�w */
struct gg_http *gg_token(int async);
int gg_token_watch_fd(struct gg_http *h);
void gg_token_free(struct gg_http *h);

/* rejestracja nowego numerka */
struct gg_http *gg_register(const char *email, const char *password, int async);
struct gg_http *gg_register2(const char *email, const char *password, const char *qa, int async);
struct gg_http *gg_register3(const char *email, const char *password, const char *tokenid, const char *tokenval, int async);
#define gg_register_watch_fd gg_pubdir_watch_fd
#define gg_register_free gg_pubdir_free
#define gg_free_register gg_pubdir_free

struct gg_http *gg_unregister(uin_t uin, const char *password, const char *email, int async);
struct gg_http *gg_unregister2(uin_t uin, const char *password, const char *qa, int async);
struct gg_http *gg_unregister3(uin_t uin, const char *password, const char *tokenid, const char *tokenval, int async);
#define gg_unregister_watch_fd gg_pubdir_watch_fd
#define gg_unregister_free gg_pubdir_free

/* przypomnienie has�a e-mailem */
struct gg_http *gg_remind_passwd(uin_t uin, int async);
struct gg_http *gg_remind_passwd2(uin_t uin, const char *tokenid, const char *tokenval, int async);
struct gg_http *gg_remind_passwd3(uin_t uin, const char *email, const char *tokenid, const char *tokenval, int async);
#define gg_remind_passwd_watch_fd gg_pubdir_watch_fd
#define gg_remind_passwd_free gg_pubdir_free
#define gg_free_remind_passwd gg_pubdir_free

/* zmiana has�a */
struct gg_http *gg_change_passwd(uin_t uin, const char *passwd, const char *newpasswd, const char *newemail, int async);
struct gg_http *gg_change_passwd2(uin_t uin, const char *passwd, const char *newpasswd, const char *email, const char *newemail, int async);
struct gg_http *gg_change_passwd3(uin_t uin, const char *passwd, const char *newpasswd, const char *qa, int async);
struct gg_http *gg_change_passwd4(uin_t uin, const char *email, const char *passwd, const char *newpasswd, const char *tokenid, const char *tokenval, int async);
#define gg_change_passwd_free gg_pubdir_free
#define gg_free_change_passwd gg_pubdir_free

/*
 * struct gg_change_info_request
 *
 * opis ��dania zmiany informacji w katalogu publicznym.
 */
struct gg_change_info_request {
	char *first_name;	/* imi� */
	char *last_name;	/* nazwisko */
	char *nickname;		/* pseudonim */
	char *email;		/* email */
	int born;		/* rok urodzenia */
	int gender;		/* p�e� */
	char *city;		/* miasto */
};

struct gg_change_info_request *gg_change_info_request_new(const char *first_name, const char *last_name, const char *nickname, const char *email, int born, int gender, const char *city);
void gg_change_info_request_free(struct gg_change_info_request *r);

struct gg_http *gg_change_info(uin_t uin, const char *passwd, const struct gg_change_info_request *request, int async);
#define gg_change_pubdir_watch_fd gg_pubdir_watch_fd
#define gg_change_pubdir_free gg_pubdir_free
#define gg_free_change_pubdir gg_pubdir_free

/*
 * funkcje dotycz�ce listy kontakt�w na serwerze.
 */
struct gg_http *gg_userlist_get(uin_t uin, const char *password, int async);
int gg_userlist_get_watch_fd(struct gg_http *f);
void gg_userlist_get_free(struct gg_http *f);

struct gg_http *gg_userlist_put(uin_t uin, const char *password, const char *contacts, int async);
int gg_userlist_put_watch_fd(struct gg_http *f);
void gg_userlist_put_free(struct gg_http *f);

struct gg_http *gg_userlist_remove(uin_t uin, const char *password, int async);
int gg_userlist_remove_watch_fd(struct gg_http *f);
void gg_userlist_remove_free(struct gg_http *f);



/*
 * funkcje dotycz�ce komunikacji mi�dzy klientami.
 */
extern int gg_dcc_port;			/* port, na kt�rym nas�uchuje klient */
extern unsigned long gg_dcc_ip;		/* adres, na kt�rym nas�uchuje klient */

int gg_dcc_request(struct gg_session *sess, uin_t uin);

struct gg_dcc *gg_dcc_send_file(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
struct gg_dcc *gg_dcc_get_file(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
struct gg_dcc *gg_dcc_voice_chat(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
void gg_dcc_set_type(struct gg_dcc *d, int type);
int gg_dcc_fill_file_info(struct gg_dcc *d, const char *filename);
int gg_dcc_fill_file_info2(struct gg_dcc *d, const char *filename, const char *local_filename);
int gg_dcc_voice_send(struct gg_dcc *d, char *buf, int length);

#define GG_DCC_VOICE_FRAME_LENGTH 195
#define GG_DCC_VOICE_FRAME_LENGTH_505 326

struct gg_dcc *gg_dcc_socket_create(uin_t uin, uint16_t port);
#define gg_dcc_socket_free gg_free_dcc
#define gg_dcc_socket_watch_fd gg_dcc_watch_fd

struct gg_event *gg_dcc_watch_fd(struct gg_dcc *d);

void gg_dcc_free(struct gg_dcc *c);
#define gg_free_dcc gg_dcc_free

/*
 * je�li chcemy sobie podebugowa�, wystarczy ustawi� `gg_debug_level'.
 * niestety w miar� przybywania wpis�w `gg_debug(...)' nie chcia�o mi
 * si� ustawia� odpowiednich leveli, wi�c wi�kszo�� sz�a do _MISC.
 */
extern int gg_debug_level;	/* poziom debugowania. mapa bitowa sta�ych GG_DEBUG_* */

/*
 * mo�na poda� wska�nik do funkcji obs�uguj�cej wywo�ania gg_debug().
 * nieoficjalne, nieudokumentowane, mo�e si� zmieni�. je�li kto� jest
 * zainteresowany, niech da zna� na ekg-devel.
 */
extern void (*gg_debug_handler)(int level, const char *format, va_list ap);
extern void (*gg_debug_handler_session)(struct gg_session *sess, int level, const char *format, va_list ap);

/*
 * mo�na poda� plik, do kt�rego b�d� zapisywane teksty z gg_debug().
 */
extern FILE *gg_debug_file;

#define GG_DEBUG_NET 1
#define GG_DEBUG_TRAFFIC 2
#define GG_DEBUG_DUMP 4
#define GG_DEBUG_FUNCTION 8
#define GG_DEBUG_MISC 16

#ifdef GG_DEBUG_DISABLE
#define gg_debug(x, y...) do { } while(0)
#define gg_debug_session(z, x, y...) do { } while(0)
#else
void gg_debug(int level, const char *format, ...);
void gg_debug_session(struct gg_session *sess, int level, const char *format, ...);
#endif

const char *gg_libgadu_version(void);

/*
 * konfiguracja http proxy.
 */
extern int gg_proxy_enabled;		/* w��cza obs�ug� proxy */
extern char *gg_proxy_host;		/* okre�la adres serwera proxy */
extern int gg_proxy_port;		/* okre�la port serwera proxy */
extern char *gg_proxy_username;		/* okre�la nazw� u�ytkownika przy autoryzacji serwera proxy */
extern char *gg_proxy_password;		/* okre�la has�o u�ytkownika przy autoryzacji serwera proxy */
extern int gg_proxy_http_only;		/* w��cza obs�ug� proxy wy��cznie dla us�ug HTTP */


/*
 * adres, z kt�rego �lemy pakiety (np ��czymy si� z serwerem)
 * u�ywany przy gg_connect()
 */
extern unsigned long gg_local_ip;
/*
 * -------------------------------------------------------------------------
 * poni�ej znajduj� si� wewn�trzne sprawy biblioteki. zwyk�y klient nie
 * powinien ich w og�le rusza�, bo i nie ma po co. wszystko mo�na za�atwi�
 * procedurami wy�szego poziomu, kt�rych definicje znajduj� si� na pocz�tku
 * tego pliku.
 * -------------------------------------------------------------------------
 */

#ifdef GG_CONFIG_HAVE_PTHREAD
int gg_resolve_pthread(int *fd, void **resolver, const char *hostname);
void gg_resolve_pthread_cleanup(void *resolver, int kill);
#endif

#ifdef _WIN32
int gg_thread_socket(int thread_id, int socket);
#endif

int gg_resolve(int *fd, int *pid, const char *hostname);

#ifdef __GNUC__
char *gg_saprintf(const char *format, ...) __attribute__ ((format (printf, 1, 2)));
#else
char *gg_saprintf(const char *format, ...);
#endif

char *gg_vsaprintf(const char *format, va_list ap);

#define gg_alloc_sprintf gg_saprintf

char *gg_get_line(char **ptr);

int gg_connect(void *addr, int port, int async);
struct in_addr *gg_gethostbyname(const char *hostname);
char *gg_read_line(int sock, char *buf, int length);
void gg_chomp(char *line);
char *gg_urlencode(const char *str);
int gg_http_hash(const char *format, ...);
int gg_read(struct gg_session *sess, char *buf, int length);
int gg_write(struct gg_session *sess, const char *buf, int length);
void *gg_recv_packet(struct gg_session *sess);
int gg_send_packet(struct gg_session *sess, int type, ...);
unsigned int gg_login_hash(const unsigned char *password, unsigned int seed);
uint32_t gg_fix32(uint32_t x);
uint16_t gg_fix16(uint16_t x);
#define fix16 gg_fix16
#define fix32 gg_fix32
char *gg_proxy_auth(void);
char *gg_base64_encode(const char *buf);
char *gg_base64_decode(const char *buf);
int gg_image_queue_remove(struct gg_session *s, struct gg_image_queue *q, int freeq);

#define GG_APPMSG_HOST "appmsg.gadu-gadu.pl"
#define GG_APPMSG_PORT 80
#define GG_PUBDIR_HOST "pubdir.gadu-gadu.pl"
#define GG_PUBDIR_PORT 80
#define GG_REGISTER_HOST "register.gadu-gadu.pl"
#define GG_REGISTER_PORT 80
#define GG_REMIND_HOST "retr.gadu-gadu.pl"
#define GG_REMIND_PORT 80

#define GG_DEFAULT_PORT 8074
#define GG_HTTPS_PORT 443
#define GG_HTTP_USERAGENT "Mozilla/4.7 [en] (Win98; I)"

#define GG_DEFAULT_CLIENT_VERSION "6, 1, 0, 158"
#define GG_DEFAULT_PROTOCOL_VERSION 0x24
#define GG_DEFAULT_TIMEOUT 30
#define GG_HAS_AUDIO_MASK 0x40000000
#define GG_ERA_OMNIX_MASK 0x04000000
#define GG_LIBGADU_VERSION "CVS"

#define GG_DEFAULT_DCC_PORT 1550

struct gg_header {
	uint32_t type;			/* typ pakietu */
	uint32_t length;		/* d�ugo�� reszty pakietu */
} GG_PACKED;

#define GG_WELCOME 0x0001
#define GG_NEED_EMAIL 0x0014

struct gg_welcome {
	uint32_t key;			/* klucz szyfrowania has�a */
} GG_PACKED;

#define GG_LOGIN 0x000c

struct gg_login {
	uint32_t uin;			/* m�j numerek */
	uint32_t hash;			/* hash has�a */
	uint32_t status;		/* status na dzie� dobry */
	uint32_t version;		/* moja wersja klienta */
	uint32_t local_ip;		/* m�j adres ip */
	uint16_t local_port;		/* port, na kt�rym s�ucham */
} GG_PACKED;

#define GG_LOGIN_EXT 0x0013

struct gg_login_ext {
	uint32_t uin;			/* m�j numerek */
	uint32_t hash;			/* hash has�a */
	uint32_t status;		/* status na dzie� dobry */
	uint32_t version;		/* moja wersja klienta */
	uint32_t local_ip;		/* m�j adres ip */
	uint16_t local_port;		/* port, na kt�rym s�ucham */
	uint32_t external_ip;		/* zewn�trzny adres ip */
	uint16_t external_port;		/* zewn�trzny port */
} GG_PACKED;

#define GG_LOGIN60 0x0015

struct gg_login60 {
	uint32_t uin;			/* m�j numerek */
	uint32_t hash;			/* hash has�a */
	uint32_t status;		/* status na dzie� dobry */
	uint32_t version;		/* moja wersja klienta */
	uint8_t dunno1;			/* 0x00 */
	uint32_t local_ip;		/* m�j adres ip */
	uint16_t local_port;		/* port, na kt�rym s�ucham */
	uint32_t external_ip;		/* zewn�trzny adres ip */
	uint16_t external_port;		/* zewn�trzny port */
	uint8_t image_size;		/* maksymalny rozmiar grafiki w KiB */
	uint8_t dunno2;			/* 0xbe */
} GG_PACKED;

#define GG_LOGIN_OK 0x0003

#define GG_LOGIN_FAILED 0x0009

#define GG_PUBDIR50_REQUEST 0x0014

#define GG_PUBDIR50_WRITE 0x01
#define GG_PUBDIR50_READ 0x02
#define GG_PUBDIR50_SEARCH 0x03
#define GG_PUBDIR50_SEARCH_REQUEST GG_PUBDIR50_SEARCH
#define GG_PUBDIR50_SEARCH_REPLY 0x05

struct gg_pubdir50_request {
	uint8_t type;			/* GG_PUBDIR50_* */
	uint32_t seq;			/* czas wys�ania zapytania */
} GG_PACKED;

#define GG_PUBDIR50_REPLY 0x000e

struct gg_pubdir50_reply {
	uint8_t type;			/* GG_PUBDIR50_* */
	uint32_t seq;			/* czas wys�ania zapytania */
} GG_PACKED;

#define GG_NEW_STATUS 0x0002

#define GG_STATUS_NOT_AVAIL 0x0001		/* niedost�pny */
#define GG_STATUS_NOT_AVAIL_DESCR 0x0015	/* niedost�pny z opisem (4.8) */
#define GG_STATUS_AVAIL 0x0002			/* dost�pny */
#define GG_STATUS_AVAIL_DESCR 0x0004		/* dost�pny z opisem (4.9) */
#define GG_STATUS_BUSY 0x0003			/* zaj�ty */
#define GG_STATUS_BUSY_DESCR 0x0005		/* zaj�ty z opisem (4.8) */
#define GG_STATUS_INVISIBLE 0x0014		/* niewidoczny (4.6) */
#define GG_STATUS_INVISIBLE_DESCR 0x0016	/* niewidoczny z opisem (4.9) */
#define GG_STATUS_BLOCKED 0x0006		/* zablokowany */

#define GG_STATUS_FRIENDS_MASK 0x8000		/* tylko dla znajomych (4.6) */

#define GG_STATUS_DESCR_MAXSIZE 70

/*
 * makra do �atwego i szybkiego sprawdzania stanu.
 */

/* GG_S_F() tryb tylko dla znajomych */
#define GG_S_F(x) (((x) & GG_STATUS_FRIENDS_MASK) != 0)

/* GG_S() stan bez uwzgl�dnienia trybu tylko dla znajomych */
#define GG_S(x) ((x) & ~GG_STATUS_FRIENDS_MASK)

/* GG_S_A() dost�pny */
#define GG_S_A(x) (GG_S(x) == GG_STATUS_AVAIL || GG_S(x) == GG_STATUS_AVAIL_DESCR)

/* GG_S_NA() niedost�pny */
#define GG_S_NA(x) (GG_S(x) == GG_STATUS_NOT_AVAIL || GG_S(x) == GG_STATUS_NOT_AVAIL_DESCR)

/* GG_S_B() zaj�ty */
#define GG_S_B(x) (GG_S(x) == GG_STATUS_BUSY || GG_S(x) == GG_STATUS_BUSY_DESCR)

/* GG_S_I() niewidoczny */
#define GG_S_I(x) (GG_S(x) == GG_STATUS_INVISIBLE || GG_S(x) == GG_STATUS_INVISIBLE_DESCR)

/* GG_S_D() stan opisowy */
#define GG_S_D(x) (GG_S(x) == GG_STATUS_NOT_AVAIL_DESCR || GG_S(x) == GG_STATUS_AVAIL_DESCR || GG_S(x) == GG_STATUS_BUSY_DESCR || GG_S(x) == GG_STATUS_INVISIBLE_DESCR)

/* GG_S_BL() blokowany lub blokuj�cy */
#define GG_S_BL(x) (GG_S(x) == GG_STATUS_BLOCKED)

struct gg_new_status {
	uint32_t status;			/* na jaki zmieni�? */
} GG_PACKED;

#define GG_NOTIFY_FIRST 0x000f
#define GG_NOTIFY_LAST 0x0010

#define GG_NOTIFY 0x0010

struct gg_notify {
	uint32_t uin;				/* numerek danej osoby */
	uint8_t dunno1;				/* rodzaj wpisu w li�cie */
} GG_PACKED;

#define GG_USER_OFFLINE 0x01	/* b�dziemy niewidoczni dla u�ytkownika */
#define GG_USER_NORMAL 0x03	/* zwyk�y u�ytkownik */
#define GG_USER_BLOCKED 0x04	/* zablokowany u�ytkownik */

#define GG_LIST_EMPTY 0x0012

#define GG_NOTIFY_REPLY 0x000c	/* tak, to samo co GG_LOGIN */

struct gg_notify_reply {
	uint32_t uin;			/* numerek */
	uint32_t status;		/* status danej osoby */
	uint32_t remote_ip;		/* adres ip delikwenta */
	uint16_t remote_port;		/* port, na kt�rym s�ucha klient */
	uint32_t version;		/* wersja klienta */
	uint16_t dunno2;		/* znowu port? */
} GG_PACKED;

#define GG_NOTIFY_REPLY60 0x0011

struct gg_notify_reply60 {
	uint32_t uin;			/* numerek plus flagi w MSB */
	uint8_t status;			/* status danej osoby */
	uint32_t remote_ip;		/* adres ip delikwenta */
	uint16_t remote_port;		/* port, na kt�rym s�ucha klient */
	uint8_t version;		/* wersja klienta */
	uint8_t image_size;		/* maksymalny rozmiar grafiki w KiB */
	uint8_t dunno1;			/* 0x00 */
} GG_PACKED;

#define GG_STATUS60 0x000f

struct gg_status60 {
	uint32_t uin;			/* numerek plus flagi w MSB */
	uint8_t status;			/* status danej osoby */
	uint32_t remote_ip;		/* adres ip delikwenta */
	uint16_t remote_port;		/* port, na kt�rym s�ucha klient */
	uint8_t version;		/* wersja klienta */
	uint8_t image_size;		/* maksymalny rozmiar grafiki w KiB */
	uint8_t dunno1;			/* 0x00 */
} GG_PACKED;

#define GG_ADD_NOTIFY 0x000d
#define GG_REMOVE_NOTIFY 0x000e

struct gg_add_remove {
	uint32_t uin;			/* numerek */
	uint8_t dunno1;			/* bitmapa */
} GG_PACKED;

#define GG_STATUS 0x0002

struct gg_status {
	uint32_t uin;			/* numerek */
	uint32_t status;		/* nowy stan */
} GG_PACKED;

#define GG_SEND_MSG 0x000b

#define GG_CLASS_QUEUED 0x0001
#define GG_CLASS_OFFLINE GG_CLASS_QUEUED
#define GG_CLASS_MSG 0x0004
#define GG_CLASS_CHAT 0x0008
#define GG_CLASS_CTCP 0x0010
#define GG_CLASS_ACK 0x0020
#define GG_CLASS_EXT GG_CLASS_ACK	/* kompatybilno�� wstecz */

#define GG_MSG_MAXSIZE 2000

struct gg_send_msg {
	uint32_t recipient;
	uint32_t seq;
	uint32_t msgclass;
} GG_PACKED;

struct gg_msg_richtext {
	uint8_t flag;
	uint16_t length;
} GG_PACKED;

struct gg_msg_richtext_format {
	uint16_t position;
	uint8_t font;
} GG_PACKED;

struct gg_msg_richtext_image {
	uint16_t unknown1;
	uint32_t size;
	uint32_t crc32;
} GG_PACKED;

#define GG_FONT_BOLD 0x01
#define GG_FONT_ITALIC 0x02
#define GG_FONT_UNDERLINE 0x04
#define GG_FONT_COLOR 0x08
#define GG_FONT_IMAGE 0x80

struct gg_msg_richtext_color {
	uint8_t red;
	uint8_t green;
	uint8_t blue;
} GG_PACKED;

struct gg_msg_recipients {
	uint8_t flag;
	uint32_t count;
} GG_PACKED;

struct gg_msg_image_request {
	uint8_t flag;
	uint32_t size;
	uint32_t crc32;
} GG_PACKED;

struct gg_msg_image_reply {
	uint8_t flag;
	uint32_t size;
	uint32_t crc32;
	/* char filename[]; */
	/* char image[]; */
} GG_PACKED;

#define GG_SEND_MSG_ACK 0x0005

#define GG_ACK_BLOCKED 0x0001
#define GG_ACK_DELIVERED 0x0002
#define GG_ACK_QUEUED 0x0003
#define GG_ACK_MBOXFULL 0x0004
#define GG_ACK_NOT_DELIVERED 0x0006

struct gg_send_msg_ack {
	uint32_t status;
	uint32_t recipient;
	uint32_t seq;
} GG_PACKED;

#define GG_RECV_MSG 0x000a

struct gg_recv_msg {
	uint32_t sender;
	uint32_t seq;
	uint32_t time;
	uint32_t msgclass;
} GG_PACKED;

#define GG_PING 0x0008

#define GG_PONG 0x0007

#define GG_DISCONNECTING 0x000b

#define GG_USERLIST_REQUEST 0x0016

#define GG_USERLIST_PUT 0x00
#define GG_USERLIST_PUT_MORE 0x01
#define GG_USERLIST_GET 0x02

struct gg_userlist_request {
	uint8_t type;
} GG_PACKED;

#define GG_USERLIST_REPLY 0x0010

#define GG_USERLIST_PUT_REPLY 0x00
#define GG_USERLIST_PUT_MORE_REPLY 0x02
#define GG_USERLIST_GET_REPLY 0x06
#define GG_USERLIST_GET_MORE_REPLY 0x04

struct gg_userlist_reply {
	uint8_t type;
} GG_PACKED;

/*
 * pakiety, sta�e, struktury dla DCC
 */

struct gg_dcc_tiny_packet {
	uint8_t type;		/* rodzaj pakietu */
} GG_PACKED;

struct gg_dcc_small_packet {
	uint32_t type;		/* rodzaj pakietu */
} GG_PACKED;

struct gg_dcc_big_packet {
	uint32_t type;		/* rodzaj pakietu */
	uint32_t dunno1;		/* niewiadoma */
	uint32_t dunno2;		/* niewiadoma */
} GG_PACKED;

/*
 * p�ki co, nie znamy dok�adnie protoko�u. nie wiemy, co czemu odpowiada.
 * nazwy s� niepowa�ne i tymczasowe.
 */
#define GG_DCC_WANT_FILE 0x0003		/* peer chce plik */
#define GG_DCC_HAVE_FILE 0x0001		/* wi�c mu damy */
#define GG_DCC_HAVE_FILEINFO 0x0003	/* niech ma informacje o pliku */
#define GG_DCC_GIMME_FILE 0x0006	/* peer jest pewny */
#define GG_DCC_CATCH_FILE 0x0002	/* wysy�amy plik */

#define GG_DCC_FILEATTR_READONLY 0x0020

#define GG_DCC_TIMEOUT_SEND 1800	/* 30 minut */
#define GG_DCC_TIMEOUT_GET 1800		/* 30 minut */
#define GG_DCC_TIMEOUT_FILE_ACK 300	/* 5 minut */
#define GG_DCC_TIMEOUT_VOICE_ACK 300	/* 5 minut */

#ifdef __cplusplus
}
#ifdef _WIN32
#pragma pack(pop)
#endif
#endif

#endif /* __GG_LIBGADU_H */

/*
 * Local variables:
 * c-indentation-style: k&r
 * c-basic-offset: 8
 * indent-tabs-mode: notnil
 * End:
 *
 * vim: shiftwidth=8:
 */
