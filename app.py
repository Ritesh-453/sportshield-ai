from flask import Flask, render_template, send_from_directory
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY')
app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER')
app.config['DATABASE'] = os.getenv('DATABASE')

from database.db import init_db
init_db(app.config['DATABASE'])

from routes.assets import assets_bp
from routes.scan import scan_bp
from routes.report import report_bp

app.register_blueprint(assets_bp)
app.register_blueprint(scan_bp)
app.register_blueprint(report_bp)

@app.route('/')
def index():
    from routes.dashboard import get_dashboard_data
    data = get_dashboard_data(app.config['DATABASE'])
    return render_template('index.html', **data)

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/sdg')
def sdg():
    return render_template('sdg.html')

if __name__ == '__main__':
    app.run(debug=True)