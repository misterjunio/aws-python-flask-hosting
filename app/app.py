from flask import Flask, send_from_directory
from markupsafe import escape
import os

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello, World!'


@app.route('/<name>')
def hello(name):
    app.logger.info(f'Saying hello to {name}')
    return f'Hello, {escape(name)}!'


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')


if __name__ == '__main__':
    app.run(debug=True)
