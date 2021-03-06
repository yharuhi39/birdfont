#!/usr/bin/python3
""" Copyright (C) 2013 2014 2015 Johan Mattsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import os
import subprocess
import glob
import platform
import sys
from optparse import OptionParser
from scripts import config
from scripts import version
from scripts.run import run

def getDest (file, dir):
	f = dest + prefix + dir + '/'
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	return f

def getDestRoot (file, dir):
	f = dest + dir + '/'
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	return f
	
def install (file, dir, mode):
	f = getDest (file, dir)
	print ("install: " + f)
	run ('install -d ' + dest + prefix + dir)
	run ('install -m ' + str(mode) + ' ' + file + ' ' + dest + prefix + dir + '/')

def install_root (file, dir, mode):
	f = getDestRoot (file, dir)
	print ("install: " + f)
	run ('install -d ' + dest + dir)
	run ('install -m ' + str(mode) + ' ' + file + ' ' + dest + dir + '/')

def link (dir, file, linkname):
	f = getDest (linkname, dir)
	print ("install link: " + f)
	run ('cd ' + dest + prefix + dir + ' && ln -sf ' + file + ' ' + linkname)
	
if not os.path.exists ("build/configured"):
	print ("Project is not configured")
	exit (1)

parser = OptionParser()
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-m", "--nogzip", dest="nogzip", help="don't gzip manpages", default=False)
parser.add_option ("-n", "--manpages-directory", dest="mandir", help="put man pages in this directory under prefix")
parser.add_option ("-l", "--libdir", dest="libdir", help="path to directory for shared libraries (lib or lib64).")
parser.add_option ("-c", "--skip-command-line-tools", dest="nocli", help="don't install command line tools")
parser.add_option ("-a", "--apport", dest="apport", help="install apport scripts", default=True)
parser.add_option ('-v', '--development', dest='development', action="store_true", help='install development files', metavar='DEVELOPMENT')

(options, args) = parser.parse_args()

if not options.dest:
	options.dest = ""

if not options.nocli:
	options.nocli = False

nogzip = options.nogzip

if not options.mandir:
	mandir = "/man/man1"
else: 
	mandir = options.mandir

prefix = config.PREFIX
dest = options.dest

# install it:
install ('resources/icons.bf', '/share/birdfont', 644)
install ('resources/bright.theme', '/share/birdfont', 644)
install ('resources/dark.theme', '/share/birdfont', 644)
install ('resources/high_contrast.theme', '/share/birdfont', 644)
install ('resources/key_bindings.xml', '/share/birdfont', 644)
install ('resources/linux/birdfont_window_icon.png', '/share/birdfont', 644)
install ('resources/linux/birdfont.desktop', '/share/applications', 644)
install ('resources/ucd.sqlite', '/share/birdfont', 644)
install ('resources/codepages.sqlite', '/share/birdfont', 644)
install ('resources/Roboto-Regular.ttf', '/share/birdfont', 644)

install ('resources/linux/256x256/birdfont.png', '/share/icons/hicolor/256x256/apps', 644)
install ('resources/linux/128x128/birdfont.png', '/share/icons/hicolor/128x128/apps', 644)
install ('resources/linux/48x48/birdfont.png', '/share/icons/hicolor/48x48/apps', 644)

install ('resources/linux/birdfont.appdata.xml', '/share/appdata', 644)

if os.path.isfile ('build/bin/birdfont'):
	install ('build/bin/birdfont', '/bin', 755)

if not options.nocli:
	install ('build/bin/birdfont-autotrace', '/bin', 755)
	install ('build/bin/birdfont-export', '/bin', 755)
	install ('build/bin/birdfont-import', '/bin', 755)

#library
if sys.platform == 'darwin':
	libdir = '/lib'
elif not options.libdir:
	
	if platform.dist()[0] == 'Ubuntu' or platform.dist()[0] == 'Debian':
		process = subprocess.Popen(['dpkg-architecture', '-qDEB_HOST_MULTIARCH'], stdout=subprocess.PIPE)
		out, err = process.communicate()
		libdir = '/lib/' + out.decode('UTF-8').rstrip ('\n')
	else:
		p = platform.machine()
		if p == 'i386' or p == 's390' or p == 'ppc' or p == 'armv7hl':
			libdir = '/lib'
		elif p == 'x86_64' or p == 's390x' or p == 'ppc64':
			libdir = '/lib64'
		else:
			libdir = '/lib'
else:
	libdir = options.libdir

if "openbsd" in sys.platform:
	install ('build/bin/libbirdfont.so.' + '${LIBbirdfont_VERSION}', '/lib', 644)
elif os.path.isfile ('build/bin/libbirdfont.so.' + version.SO_VERSION):
	install ('build/bin/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so')
elif os.path.isfile ('build/libbirdfont.so.' + version.SO_VERSION):
	install ('build/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so')
elif os.path.isfile ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib'):
	install ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib', libdir, 644)
	link (libdir, 'libbirdfont.' + version.SO_VERSION + '.dylib', ' libbirdfont.dylib.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.' + version.SO_VERSION + '.dylib', ' libbirdfont.dylib')
else:
	print ("Can't find libbirdfont.")
	exit (1)

if "openbsd" in sys.platform:
        install ('build/bin/libbirdgems.so.' + '${LIBbirdgems_VERSION}', '/lib', 644)
elif os.path.isfile ('build/bin/libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION):
        install ('build/bin/libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, libdir, 644)
        link (libdir, 'libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, ' libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION_MAJOR)
        link (libdir, 'libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, ' libbirdgems.so')
elif os.path.isfile ('build/libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION):
        install ('build/libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, libdir, 644)
        link (libdir, 'libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, ' libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION_MAJOR)
        link (libdir, 'libbirdgems.so.' + version.LIBBIRDGEMS_SO_VERSION, ' libbirdgems.so')
elif os.path.isfile ('build/bin/libbirdgems.' + version.LIBBIRDGEMS_SO_VERSION + '.dylib'):
        install ('build/bin/libbirdgems.' + version.LIBBIRDGEMS_SO_VERSION + '.dylib', libdir, 644)
        link (libdir, 'libbirdgems.' + version.LIBBIRDGEMS_SO_VERSION + '.dylib', ' libbirdgems.dylib.' + version.LIBBIRDGEMS_SO_VERSION_MAJOR)
        link (libdir, 'libbirdgems.' + version.LIBBIRDGEMS_SO_VERSION + '.dylib', ' libbirdgems.dylib')
else:
	print ("Can't find libbirdgems, version: " + version.LIBBIRDGEMS_SO_VERSION)
	exit (1)

if "openbsd" in sys.platform:
        install ('build/bin/libsvgbird.so.' + '${LIBsvgbird_VERSION}', '/lib', 644)
elif os.path.isfile ('build/bin/libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION):
        install ('build/bin/libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, libdir, 644)
        link (libdir, 'libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, ' libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION_MAJOR)
        link (libdir, 'libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, ' libsvgbird.so')
elif os.path.isfile ('build/libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION):
        install ('build/libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, libdir, 644)
        link (libdir, 'libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, ' libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION_MAJOR)
        link (libdir, 'libsvgbird.so.' + version.LIBSVGBIRD_SO_VERSION, ' libsvgbird.so')
elif os.path.isfile ('build/bin/libsvgbird.' + version.LIBSVGBIRD_SO_VERSION + '.dylib'):
        install ('build/bin/libsvgbird.' + version.LIBSVGBIRD_SO_VERSION + '.dylib', libdir, 644)
        link (libdir, 'libsvgbird.' + version.LIBSVGBIRD_SO_VERSION + '.dylib', ' libsvgbird.dylib.' + version.LIBSVGBIRD_SO_VERSION_MAJOR)
        link (libdir, 'libsvgbird.' + version.LIBSVGBIRD_SO_VERSION + '.dylib', ' libsvgbird.dylib')
else:
	print ("Can't find libsvgbird, version: " + version.LIBSVGBIRD_SO_VERSION)
	exit (1)

#manpages
if not nogzip:
    install ('build/birdfont.1.gz', mandir, 644)

    if not options.nocli:
        install ('build/birdfont-autotrace.1.gz', mandir, 644)
        install ('build/birdfont-export.1.gz', mandir, 644)
        install ('build/birdfont-import.1.gz', mandir, 644)
else:
    install ('resources/linux/birdfont.1', mandir, 644)

    if not options.nocli:
        install ('resources/linux/birdfont-autotrace.1', mandir, 644)
        install ('resources/linux/birdfont-export.1', mandir, 644)
        install ('resources/linux/birdfont-import.1', mandir, 644)

#translations
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' , 644);

#file type 
install ('resources/linux/birdfont.xml', '/share/mime/packages', 644)

#apport hooks
if options.apport == "True":
	install ('resources/birdfont.py', '/share/apport/package-hooks', 644)
	install ('resources/source_birdfont.py', '/share/apport/package-hooks', 644)
	install_root ('resources/birdfont-crashdb.conf', '/etc/apport/crashdb.conf.d', 644)

#install development files
if options.development:
	install ('build/libsvgbird/svgbird.h', '/include', 644)
	install ('build/libsvgbird/point_value.h', '/include', 644)
	install ('svgbird.vapi', '/share/vala/vapi', 644)
	install ('svgbird.deps', '/share/vala/vapi', 644)
	install ('build/svgbird.pc', libdir + '/pkgconfig', 644)
