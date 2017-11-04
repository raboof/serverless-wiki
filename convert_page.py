#!/usr/bin/env python

import sys
import fileinput
import templating

markdown = ''
for line in fileinput.input():
  markdown += line

print(templating(markdown))
