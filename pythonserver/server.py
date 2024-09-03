from flask import Flask, request
import os
import runs_for_path_finding as paths

app = Flask(__name__)
global index
index=0
global number_of_path
number_of_path=7

@app.route('/get_obstacles')
def get_obstacles():
    global index
    circles_center_and_radius=paths.get_i_run(index%number_of_path+1)()[1]
    print(circles_center_and_radius)
    return {"points": circles_center_and_radius}

@app.route('/update_index')
def update_index():
    global index
    index+=1
    return {"ok": "ok"}


@app.route('/get_path')
def get_path():
    global index
    shortest_path=paths.get_i_run(index%number_of_path+1)()[0]
    return {"points": shortest_path}

@app.route('/post_data', methods=['POST'])
def post_data():
    data = request.get_json()
    print(data)
    # process the data
    return "Data received successfully"

if __name__ == '__main__':
    app.run()