#!/usr/bin/env python

import sys
import fileinput
import os
import templating

markdown = ''
for line in fileinput.input():
  markdown += line

print(templating.apply_template(markdown))
