rem Goto http://www.gtk.org/download-windows.html, download an all-in-one bundle of GTK+.
rem Extract contents to c:\strawberry\gtk 

rem ##########
rem reference libraries
cd /d C:\strawberry\gtk\lib

rem Glib
dlltool --input-def glib-2.0.def --output-lib libglib-2.0.a --dllname libglib-2.0-0.dll
dlltool --input-def gobject-2.0.def --output-lib libgobject-2.0.a --dllname libgobject-2.0-0.dll
dlltool --input-def gthread-2.0.def --output-lib libgthread-2.0.a --dllname libgthread-2.0-0.dll

rem gendef gendef c:\strawberry\c\bin\libintl-8.dll
rename libintl.def intl.def
dlltool --input-def intl.def --output-lib libintl.a --dllname intl.dll
dlltool --input-def fontconfig.def --output-lib libfontconfig.a --dllname libfontconfig-1.dll

rem Cairo
dlltool --input-def cairo.def --output-lib libcairo.a --dllname libcairo-2.dll

rem Pango
dlltool --input-def pango-1.0.def --output-lib libpango-1.0.a --dllname libpango-1.0-0.dll
dlltool --input-def gmodule-2.0.def --output-lib libgmodule-2.0.a --dllname libgmodule-2.0-0.dll
dlltool --input-def pangocairo-1.0.def --output-lib libpangocairo-1.0.a --dllname libpangocairo-1.0-0.dll
dlltool --input-def pangowin32-1.0.def --output-lib libpangowin32-1.0.a --dllname pangowin32-1.0-0.dll
dlltool --input-def pangoft2-1.0.def --output-lib libpangoft2-1.0.a --dllname libpangoft2-1.0-0.dll

rem Gtk2
dlltool --input-def atk-1.0.def --output-lib libatk-1.0.a --dllname libatk-1.0-0.dll
dlltool --input-def gio-2.0.def --output-lib libgio-2.0.a --dllname libgio-2.0-0.dll

reimp -d gdk-win32-2.0.lib
rem gendef c:\strawberry\c\bin\libgdk-win32-2.0-0.dll
rename libgdk-win32-2.0-0.def gdk-win32-2.0.def
dlltool --input-def gdk-win32-2.0.def --output-lib libgdk-win32-2.0.a --dllname libgdk-win32-2.0-0.dll

reimp -d gtk-win32-2.0.lib
rem gendef c:\strawberry\c\bin\libgtk-win32-2.0-0.dll
rename libgtk-win32-2.0-0.def gtk-win32-2.0.def
dlltool --input-def gtk-win32-2.0.def --output-lib libgtk-win32-2.0.a --dllname libgtk-win32-2.0-0.dll

reimp -d gdk_pixbuf-2.0.lib
rem gendef c:\strawberry\c\bin\libgdk_pixbuf-2.0-0.dll
rename libgdk_pixbuf-2.0-0.def gdk_pixbuf-2.0.def
dlltool --input-def gdk_pixbuf-2.0.def --output-lib libgdk_pixbuf-2.0.a --dllname libgdk_pixbuf-2.0-0.dll

rem other dlls
dlltool --input-def libtiff.def --output-lib libtiff.a --dllname libtiff3.dll
dlltool --input-def jpeg.def --output-lib jpeg.a --dllname jpeg62.dll
dlltool --input-def zlib.def --output-lib zlib.a --dllname zlib1.dll

rem gendef c:\strawberry\c\bin\libpng14-14.dll
dlltool --input-def libpng14-14.def  --output-lib libpng14.a --dllname libpng14-14.dll

reimp -d gailutil.lib
rem c:\strawberry\c\bin\libgailutil-18.dll
rename libgailutil-18.def gailutil.def
dlltool --input-def gailutil.def --output-lib libgailutil.a --dllname libgailutil-18.dll

rem ##########
rem Perl modules

rem build Glib Perl module
dlltool --input-def Glib.def --output-lib Glib.a --dllname Glib.dll
copy Glib.a C:\strawberry\perl\site\lib\auto\Glib\

rem Build Cairo Perl module
dlltool --input-def Cairo.def --output-lib Cairo.a --dllname Cairo.dll
copy Cairo.a C:\strawberry\perl\site\lib\auto\Cairo\

rem Modify pangocairo.pc
rem Libs: -L${libdir} -lpangocairo-1.0 C:/strawberry/perl/site/lib/auto/Cairo/Cairo.a

rem Build Pango Perl module
rem Open the generated Makefile and, to the EXTRALIBS and LDLOADLIBS entries (in the MakeMaker const_loadlibs section), append: 
rem C:\strawberry\perl\site\lib\auto\Glib\Glib.a C:\strawberry\perl\site\lib\auto\Cairo\Cairo.a
dlltool --input-def Pango.def --output-lib Pango.a --dllname Pango.dll
copy Pango.a C:\strawberry\perl\site\lib\auto\Pango\

rem Build Gtk2 Perl module
rem Use Gtk2-1.203. Gtk2-1.220 failed.
rem Open the generated Makefile and, to the EXTRALIBS and LDLOADLIBS entries (in the MakeMaker const_loadlibs section), append: 
rem C:\strawberry\perl\site\lib\auto\Glib\Glib.a C:\strawberry\perl\site\lib\auto\Cairo\Cairo.a C:\strawberry\perl\site\lib\auto\Pango\Pango.a
dlltool --input-def Gtk2.def --output-lib Gtk2.a --dllname Gtk2.dll
copy Gtk2.a C:\strawberry\perl\site\lib\auto\Gtk2\


