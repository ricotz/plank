#!/usr/bin/python

'''Apport package hook for plank

Copyright (C) 2012 Robert Dyer, Rico Tzschichholz

This file is part of Plank.

Plank is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Plank is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''

from apport.hookutils import *
from os import path

def add_info(report, ui=None):
	attach_file_if_exists(report, path.expanduser('~/.config/plank/dock1/settings'), 'DockSettings')

	report['SuspiciousXErrors.txt'] = xsession_errors(re.compile('\[(FATAL|WARN|ERROR|INFO|DEBUG).*'))

	if not apport.packaging.is_distro_package(report['Package'].split()[0]):
		report['ThirdParty'] = 'True'
		report['CrashDB'] = 'plank'
