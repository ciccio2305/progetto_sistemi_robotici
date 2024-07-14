from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/get_path')
def get_path():

    # ritorna una lista di punti sotto forma di json
    list_of_point=[{"x": 1, "y": 0}, {"x": 2, "y": 2}, {"x": -9, "y": -9}]
    return {"points": list_of_point}

@app.route('/post_data', methods=['POST'])
def post_data():
    data = request.get_json()
    print(data)
    # process the data
    return "Data received successfully"

if __name__ == '__main__':
    app.run()