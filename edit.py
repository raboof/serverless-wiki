import markdown2

def hello(post, context):
  return {
    'statusCode': '200',
    'body': markdown2.markdown(post['body']),
    'headers': {
      'Content-Type': 'text/html',
    },
  }
