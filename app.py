from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

@app.route('/')
def home():
    return render_template_string("<html><body><h1>My App</h1><button id='btn'>Click</button><div id='out'></div><script>document.getElementById('btn').onclick = function(){document.getElementById('out').textContent='clicked'}</script></body></html>")

@app.route('/health')
def health():
    return jsonify({"status":"ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
