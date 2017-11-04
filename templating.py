import sys
import markdown2

def apply_template(md):
  with open (sys.path[0] + "/templates/index.html", "r") as template:
    result = ''
    line = template.readline()
    while line:
      if (line == '<!-- PAGE_CONTENT_HERE -->\n'):
        # TODO further processing, e.g. handling in-wiki links
        # both to existing and non-existing pages.
        result += markdown2.markdown(md)
      elif (line == '<!-- PAGE_SOURCE_HERE -->\n'):
        result += md
      else:
        result += (line.replace('\n', ''))
      line = template.readline()
  return result
