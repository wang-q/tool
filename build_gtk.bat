rem Goto http://www.gtk.org/download-windows.html, download an all-in-one bundle of GTK+.
rem Extract contents to c:\strawberry\gtk 

rem ##########
rem reference libraries
cd /d C:\strawberry\gtk\lib

rem Glib
dlltool --input-def glib-2.0.def --output-lib libglib-2.0.a --dllname libglib-2.0-0.dll
dlltool --input-def gobject-2.0.def --output-lib libgobject-2.0.a --dllname libgobject-2.0-0.dll
dlltool --input-def gthread-2.0.def --output-lib libgthread-2.0.a --dllname libgthread-2.0-0.dll

gendef c:\strawberry\gtk\bin\libintl-8.dll
dlltool --input-def libintl-8.def --output-lib libintl.a --dllname libintl-8.dll
rem gendef c:\strawberry\gtk\bin\intl.dll
rem dlltool --input-def intl.def --output-lib libintl.a --dllname intl.dll
gendef c:\strawberry\gtk\bin\libfontconfig-1.dll
dlltool --input-def libfontconfig-1.def --output-lib libfontconfig.a --dllname libfontconfig-1.dll

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

rem reimp -d gdk-win32-2.0.lib
gendef c:\strawberry\gtk\bin\libgdk-win32-2.0-0.dll
dlltool --input-def libgdk-win32-2.0-0.def --output-lib libgdk-win32-2.0.a --dllname libgdk-win32-2.0-0.dll

rem reimp -d gtk-win32-2.0.lib
gendef c:\strawberry\gtk\bin\libgtk-win32-2.0-0.dll
dlltool --input-def libgtk-win32-2.0-0.def --output-lib libgtk-win32-2.0.a --dllname libgtk-win32-2.0-0.dll

rem reimp -d gdk_pixbuf-2.0.lib
gendef c:\strawberry\gtk\bin\libgdk_pixbuf-2.0-0.dll
dlltool --input-def libgdk_pixbuf-2.0-0.def --output-lib libgdk_pixbuf-2.0.a --dllname libgdk_pixbuf-2.0-0.dll

rem other dlls
rem dlltool --input-def libtiff.def --output-lib libtiff.a --dllname libtiff3.dll
rem dlltool --input-def jpeg.def --output-lib jpeg.a --dllname jpeg62.dll
dlltool --input-def zlib.def --output-lib zlib.a --dllname zlib1.dll

gendef c:\strawberry\gtk\bin\libpng14-14.dll
dlltool --input-def libpng14-14.def  --output-lib libpng14.a --dllname libpng14-14.dll

rem gendef c:\strawberry\gtk\bin\libpng12-0.dll
rem dlltool --input-def libpng12-0.def  --output-lib libpng12.a --dllname libpng12-0.dll

rem reimp -d gailutil.lib
gendef c:\strawberry\gtk\bin\libgailutil-18.dll
dlltool --input-def libgailutil-18.def --output-lib libgailutil.a --dllname libgailutil-18.dll

rem ##########
rem Perl modules

cpanm ExtUtils::PkgConfig 

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

rem ##########
rem Perl modules
rem Recent version EU::MM fixed most of above bugs
rem Gtk2-1.223 and gtk 2.16.6 pass on Windows 7 x64, gtk 2.20 and 2.22 passed at Glib, Cairo and Pango, but failed at Gtk2
rem Modify pangocairo.pc
rem Libs: -L${libdir} -lpangocairo-1.0 C:/strawberry/perl/site/lib/auto/Cairo/Cairo.a

rem libglade
gendef c:\strawberry\gtk\bin\libxml2-2.dll
dlltool --input-def libxml2-2.def --output-lib ibxml2.a --dllname ibxml2-2.dll


gendef c:\strawberry\gtk\bin\libglade-2.0-0.dll
dlltool --input-def libglade-2.0-0.def --output-lib libglade-2.0.a --dllname libglade-2.0-0.dll
