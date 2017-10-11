#!/usr/bin/env python

import fileinput
import markdown2

with open ("templates/index.html", "r") as template:
  line = template.readline()
  while line:
    if (line == '<!-- PAGE_CONTENT_HERE -->\n'):
      markdown = ''
      for line in fileinput.input():
        markdown += line
      # TODO further processing, e.g. handling in-wiki links
      # both to existing and non-existing pages.
      print(markdown2.markdown(markdown))
    else:
      print(line.replace('\n', ''));
    line = template.readline()
