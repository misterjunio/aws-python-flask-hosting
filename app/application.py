from flask import Flask
from markupsafe import escape

application = Flask(__name__)


@application.route('/')
def hello_world():
    return 'Hello, World!'


@application.route('/<name>')
def hello(name):
    application.logger.info(f'Saying hello to {name}')
    return f'Hello, {escape(name)}!'


if __name__ == '__main__':
    application.run(debug=True)
