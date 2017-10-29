import markdown2
import sys
import fileinput

def hello(post, context):
  with open (sys.path[0] + "/templates/index.html", "r") as template:
    result = ''
    line = template.readline()
    while line:
      if (line == '<!-- PAGE_CONTENT_HERE -->\n'):
        markdown = ''
        for line in fileinput.input():
          markdown += line
        # TODO further processing, e.g. handling in-wiki links
        # both to existing and non-existing pages.
        result += markdown2.markdown(post['body'])
      else:
        result += (line.replace('\n', ''))
      line = template.readline()

  return {
    'statusCode': '200',
    'body': result,
    'headers': {
      'Content-Type': 'text/html',
    },
  }
