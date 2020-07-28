#!/usr/bin/python
# -*- coding: utf-8 -*-

#
# csv2odf 2.09
# Copyright (C) 2016 Larry Jordan
# <http://csv2odf.sourceforge.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

import distutils.core

distutils.core.setup(name='csv2odf',
      version='2.09',
      description='Convert csv files to open document format',
      url = 'http://csv2odf.sourceforge.net',
      license='GNU GPL-3',
      author='Larry Jordan',
      author_email='w322@users.sourceforge.net',
      scripts=['csv2odf'],
      data_files=[ ('share/man/man1', ['doc/csv2odf.1']),
             ('share/doc', ['doc/copyright']),
             ('share/doc', ['debian/changelog.gz']) ],
      platforms=['any'],
      long_description='Convert a csv file to odf, ods, html, xlsx,\
 or docx format.  csv2odf is a command line tool that\
 can convert a comma separated value (csv) file to an\
 odf, ods, html, xlsx, or docx document that can be\
 viewed in LibreOffice and other office productivity\
 programs. csv2odf is useful for creating reports from\
 databases and other data sources that produce csv files.\
 csv2odf can be combined with cron and shell scripts\
 to automatically generate business reports.\
 .\
 The output format (fonts, number formatting, etc.) is\
 controlled by a template file that you design in\
 LibreOffice.\
 .\
 csv2odf is written in Python.'
     )


