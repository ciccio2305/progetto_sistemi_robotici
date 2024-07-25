import numpy as np
import matplotlib.pyplot as plt
import random
from matplotlib.patches import Rectangle, Polygon, Circle
from matplotlib.path import Path
from scipy.spatial import distance
#from multiprocessing import Pool
import networkx as nx
from flask import Flask, request
import os

app = Flask(__name__)

# Dimensione della mappa
map_size = 100
min_distance = 5  # Distanza minima dal bordo e dagli altri ostacoli
node_distance_threshold = 5  # Distanza massima per considerare i nodi come duplicati
path_finding_distance_threshold = 5  # Distanza massima per considerare i nodi per il path finding
edge_distance_threshold = 7  # Distanza massima per creare un arco tra due nodi
start_end_min_distance = 20  # Distanza minima tra start_point e end_point

# Genera una griglia di punti
x = np.linspace(0, map_size, map_size)
y = np.linspace(0, map_size, map_size)
xx, yy = np.meshgrid(x, y)
grid_points = np.c_[xx.ravel(), yy.ravel()]

# Numero di ostacoli
num_obstacles = 20

# Funzione per verificare se due ostacoli si intersecano o sono troppo vicini
def check_intersection(new_obs, obstacles):
    new_path = Path(new_obs.get_verts())
    for obs in obstacles:
        obs_path = Path(obs.get_verts())
        if new_path.intersects_path(obs_path) or new_path.intersects_path(obs_path, filled=True):
            return True
    return False

# Funzione per verificare se un ostacolo è troppo vicino al bordo della mappa
def check_distance_from_border(obstacle):
    if isinstance(obstacle, Rectangle):
        x_min, y_min = obstacle.get_xy()
        width, height = obstacle.get_width(), obstacle.get_height()
        if x_min < min_distance or y_min < min_distance or (x_min + width) > (map_size - min_distance) or (y_min + height) > (map_size - min_distance):
            return False
    elif isinstance(obstacle, Polygon):
        vertices = obstacle.get_xy()
        for x, y in vertices:
            if x < min_distance or y < min_distance or x > (map_size - min_distance) or y > (map_size - min_distance):
                return False
    elif isinstance(obstacle, Circle):
        x_center, y_center = obstacle.center
        radius = obstacle.radius
        if (x_center - radius) < min_distance or (y_center - radius) < min_distance or (x_center + radius) > (map_size - min_distance) or (y_center + radius) > (map_size - min_distance):
            return False
    return True

# Funzione per verificare se un punto è troppo vicino agli ostacoli
def check_distance_from_obstacles_point(point, obstacles):
    for obs in obstacles:
        obs_path = Path(obs.get_verts())
        if obs_path.contains_point(point):
            return False
        # Calcola la distanza minima tra il punto e i bordi degli ostacoli
        min_dist = min(distance.euclidean(point, p) for p in obs.get_verts())
        if min_dist < min_distance:
            return False
    return True

# Funzione per verificare se un ostacolo è troppo vicino ad altri ostacoli
def check_distance_from_obstacles(new_obs, obstacles):
    new_path = Path(new_obs.get_verts())
    for obs in obstacles:
        obs_path = Path(obs.get_verts())
        if new_path.intersects_path(obs_path) or new_path.intersects_path(obs_path, filled=True):
            return False
        # Calcola la distanza minima tra i bordi degli ostacoli
        min_dist = min(distance.euclidean(p1, p2) for p1 in new_obs.get_verts() for p2 in obs.get_verts())
        if min_dist < min_distance:
            return False
    return True

# Funzione per generare un rettangolo
def generate_rectangle():
    while True:
        width = random.randint(20, 100)
        height = random.randint(20, 100)
        x_min = random.randint(min_distance, map_size - width - min_distance)
        y_min = random.randint(min_distance, map_size - height - min_distance)
        new_obs = Rectangle((x_min, y_min), width, height, color='red', alpha=0.5)
        if check_distance_from_border(new_obs):
            return new_obs

# Funzione per generare un triangolo
def generate_triangle():
    while True:
        x1, y1 = random.randint(min_distance, map_size - min_distance), random.randint(min_distance, map_size - min_distance)
        x2, y2 = x1 + random.randint(20, 100), y1
        x3, y3 = x1 + random.randint(10, 50), y1 + random.randint(20, 100)
        new_obs = Polygon([(x1, y1), (x2, y2), (x3, y3)], color='blue', alpha=0.5)
        if check_distance_from_border(new_obs):
            return new_obs

# Funzione per generare un cerchio
def generate_circle():
    while True:
        radius = random.randint(1, 3)
        x_center = random.randint(radius + min_distance, map_size - radius - min_distance)
        y_center = random.randint(radius + min_distance, map_size - radius - min_distance)
        new_obs = Circle((x_center, y_center), radius, color='green', alpha=0.5)
        if check_distance_from_border(new_obs):
            return new_obs

# Funzione per ottenere i punti sul perimetro di un ostacolo
def get_perimeter_points(obstacle):
    if isinstance(obstacle, Rectangle):
        x_min, y_min = obstacle.get_xy()
        width, height = obstacle.get_width(), obstacle.get_height()
        perimeter_points = []
        print("width: "+str(width)+" height: "+str(height))
        for x in np.linspace(x_min, x_min + width, int(width/3)):
            perimeter_points.append((x, y_min))
            perimeter_points.append((x, y_min + height))
        for y in np.linspace(y_min, y_min + height, int(height/3)):
            perimeter_points.append((x_min, y))
            perimeter_points.append((x_min + width, y))
        return np.array(perimeter_points)
    elif isinstance(obstacle, Polygon):
        vertices = obstacle.get_xy()
        perimeter_points = []
        for i in range(len(vertices) - 1):
            x1, y1 = vertices[i]
            x2, y2 = vertices[i + 1]
            print("Punti del triangolo x1: "+str(x1)+" y1: "+str(y1)+" x2: "+str(x2)+" y2: "+str(y2))
            size = distance.euclidean((x1,y1), (x2,y2))
            print(str(size))
            for t in np.linspace(0, 1, int(size/3)):
                x = x1 + t * (x2 - x1)
                y = y1 + t * (y2 - y1)
                perimeter_points.append((x, y))
        return np.array(perimeter_points)
    elif isinstance(obstacle, Circle):
        center = obstacle.center
        radius = obstacle.radius
        print(str(radius))
        theta = np.linspace(0, 2 * np.pi, int(radius+10))
        return np.array([(center[0] + radius * np.cos(t), center[1] + radius * np.sin(t)) for t in theta])

# Funzione per generare i punti di confine della mappa
def generate_boundary_points(map_size):
    num_points_per_side = map_size // 4
    boundary_map_points = []
    boundary_map_points.extend([(0, y) for y in np.linspace(0, map_size, num_points_per_side)])  # Lato sinistro
    boundary_map_points.extend([(map_size, y) for y in np.linspace(0, map_size, num_points_per_side)])  # Lato destro
    boundary_map_points.extend([(x, 0) for x in np.linspace(0, map_size, num_points_per_side)])  # Lato inferiore
    boundary_map_points.extend([(x, map_size) for x in np.linspace(0, map_size, num_points_per_side)])  # Lato superiore
    return np.array(boundary_map_points)

# Funzione per verificare e rimuovere nodi duplicati vicini
def check_duplicates_near_nodes(nodes, path_vertices):
    unique_nodes = []
    for i, node in enumerate(nodes):
        if all(distance.euclidean(node, other_node) > node_distance_threshold for other_node in nodes[:i]):
            unique_nodes.append(node)
        else:
            path_vertices.append(node)
    return np.array(unique_nodes), np.array(path_vertices)

# Funzione per aumentare i nodi per il path finding
def increase_nodes_for_path_finding(nodes, path_vertices):
    new_nodes = nodes
    for vertex in path_vertices:
        if all(distance.euclidean(vertex, node) > path_finding_distance_threshold for node in new_nodes):
            new_nodes.append(vertex)
    return np.array(new_nodes), path_vertices

# Funzione per generare un punto casuale valido
def generate_valid_point(obstacles, start_point=None):
    while True:
        point = (random.randint(min_distance, map_size - min_distance), random.randint(min_distance, map_size - min_distance))
        if check_distance_from_obstacles_point(point, obstacles):
            if start_point is None or distance.euclidean(point, start_point) >= start_end_min_distance:
                return point

def find_min_distance(point):
    
    dist_sopra=500-point[1]
    dist_sotto=point[1]
    dist_sinistra=point[0]
    dist_destra=500-point[0]
    
    return min(dist_sopra,dist_sotto,dist_sinistra,dist_destra)

# Funzione per costruire il diagramma di Voronoi
def building_voronoi_diagram(grid_points, boundary_map_points, perimeter_points_dict):
    nodes = []
    path_vertices = []
    
    # Unisci tutti i punti perimetrali degli ostacoli
    all_perimeter_points = np.vstack(list(perimeter_points_dict.values()))
    contatore = len(grid_points)
    for point in grid_points:
        if contatore % 10000 == 0:
            print("Il valore di contatore è:", contatore)
        contatore = contatore -1
        if any(np.array_equal(point, bp) for bp in boundary_map_points) or any(np.array_equal(point, pp) for pp in all_perimeter_points):
            continue
        
        distances = []
        
        # Calcola la distanza dal punto ai punti di confine della mappa
        #min_distance_boundary = min(distance.euclidean(point, bp) for bp in boundary_map_points)
        min_distance_boundary = find_min_distance(point)
        
        distances.append(min_distance_boundary)
        
        # Calcola la distanza dal punto ai punti perimetrali di ciascun ostacolo
        for obs, perimeter_points in perimeter_points_dict.items():
            #min_distance_perimeter = min(distance.euclidean(point, pp) for pp in perimeter_points)
            min_distance_perimeter = distance.euclidean(point, obs.center) - obs.radius
            
            distances.append(min_distance_perimeter)
        
        # Ordina la lista delle distanze
        distances.sort()
        
        # Verifica le condizioni per identificare nodi e vertici del percorso
        if abs(distances[0] - distances[1]) < 1 and abs(distances[1] - distances[2]) < 1:
            nodes.append(point)
        elif abs(distances[0] - distances[1]) < 1:
            path_vertices.append(point)

    # Aumenta i nodi per il path finding
    nodes, path_vertices = increase_nodes_for_path_finding(nodes, path_vertices)
    
    # Verifica e rimuovi nodi duplicati vicini
    nodes, path_vertices = check_duplicates_near_nodes(nodes, path_vertices)
    
    return np.array(nodes), np.array(path_vertices)

# Funzione per eseguire la costruzione del diagramma di Voronoi in multi-processing
# def parallel_building_voronoi_diagram(grid_points, boundary_map_points, perimeter_points_dict):
#     # Dividi grid_points in 4 parti
#     grid_points_split = np.array_split(grid_points, 4)
    
#     with Pool(processes=4) as pool:
#         results = pool.starmap(building_voronoi_diagram, [(part, boundary_map_points, perimeter_points_dict) for part in grid_points_split])
    
#     # Unisci i risultati
#     nodes = np.vstack([result[0] for result in results if result[0].size > 0])
#     path_vertices = np.vstack([result[1] for result in results if result[1].size > 0])
    
#     # Aumenta i nodi per il path finding
#     nodes, path_vertices = increase_nodes_for_path_finding(nodes, path_vertices)
    
#     # Verifica e rimuovi nodi duplicati vicini
#     nodes, path_vertices = check_duplicates_near_nodes(nodes, path_vertices.tolist())
    
#     return nodes, path_vertices



# Genera ostacoli senza intersezioni e a distanza minima dal bordo e dagli altri ostacoli
obstacles = []
perimeter_points_dict = {}
circles_center_and_radius = []
while len(obstacles) < num_obstacles:
    shape_type = random.choice(['circle', 'circle', 'circle'])
    if shape_type == 'rectangle':
        new_obs = generate_rectangle()
    elif shape_type == 'triangle':
        new_obs = generate_triangle()
    elif shape_type == 'circle':
        new_obs = generate_circle()
    
    if check_distance_from_obstacles(new_obs, obstacles):
        obstacles.append(new_obs)
        perimeter_points = get_perimeter_points(new_obs)
        perimeter_points_dict[new_obs] = perimeter_points
        if isinstance(new_obs, Circle):
            circles_center_and_radius.append((new_obs.center, new_obs.radius))
        print(f'Ostacolo {len(obstacles)}: {len(perimeter_points)} punti perimetrali')

# Genera i punti di confine della mappa
boundary_map_points = generate_boundary_points(map_size)

# Costruisci il diagramma di Voronoi in multi-processing
nodes, path_vertices = building_voronoi_diagram(grid_points, boundary_map_points, perimeter_points_dict)

print(str(len(nodes)))

# Genera start_point e end_point
start_point = generate_valid_point(obstacles)
end_point = generate_valid_point(obstacles, start_point)
print("1")
# Crea il grafo
G = nx.Graph()
print("2")

# Aggiungi i nodi al grafo
for node in nodes:
    G.add_node(tuple(node))
print("3")

# Aggiungi gli archi al grafo
for i, node in enumerate(nodes):
    for j, other_node in enumerate(nodes):
        if i != j and distance.euclidean(node, other_node) <= edge_distance_threshold:
            G.add_edge(tuple(node), tuple(other_node))
print("4")

# Aggiungi start_point e end_point ai nodi del grafo
G.add_node(tuple(start_point))
G.add_node(tuple(end_point))
print("5")

# Collega start_point al nodo più vicino
closest_node_to_start = min(nodes, key=lambda node: distance.euclidean(start_point, node))
G.add_edge(tuple(start_point), tuple(closest_node_to_start))
print("6")

# Collega end_point al nodo più vicino
closest_node_to_end = min(nodes, key=lambda node: distance.euclidean(end_point, node))
G.add_edge(tuple(end_point), tuple(closest_node_to_end))
print("7")

# Trova il percorso più breve tra start_point e end_point usando Dijkstra
shortest_path = nx.dijkstra_path(G, tuple(start_point), tuple(end_point))
print("8")

# Stampa in ordine tutti i nodi attraversati nel percorso tra start_point e end_point
print("Percorso più breve tra start_point e end_point:")
for node in shortest_path:
    print(node)

# Stampa le origini e i raggi delle circonferenze
print("Origini e raggi delle circonferenze:")
for center, radius in circles_center_and_radius:
    print(f"Centro: {center}, Raggio: {radius}")



@app.route('/get_obstacles')
def get_obstacles():

    return {"points": circles_center_and_radius}


@app.route('/get_path')
def get_path():
    return {"points": shortest_path}

@app.route('/post_data', methods=['POST'])
def post_data():
    data = request.get_json()
    print(data)
    # process the data
    return "Data received successfully"



if __name__ == '__main__':
    app.run()