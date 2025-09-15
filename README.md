# 🚀 Spark + Jupyter on Docker

This project sets up an **Apache Spark cluster** (1 master, 2 workers) and a **Jupyter Notebook** environment for running PySpark code. It uses Docker Compose for easy orchestration.

---

## 📂 Project Structure

```
.
├── docker-compose.yml   # Compose file to start all services
├── apps/                # Your Spark / PySpark jobs (mounted into containers)
├── data/                # Data shared between Spark services
├── requirements.txt     # Python dependencies for Jupyter
```

---

## ⚙️ Services

### 1️⃣ Spark Master

-   **Image:** `bitnami/spark:3.5.0`
-   **Ports:**

    -   `8080` → Spark Master Web UI (`http://localhost:8080`)
    -   `7077` → Spark Master RPC (cluster communication)

-   **Environment:**

    -   Runs in `master` mode.
    -   Exposes itself as `spark://spark-master:7077`.

-   **Volumes:**

    -   `./apps → /opt/spark-apps`
    -   `./data → /opt/spark-data`

---

### 2️⃣ Spark Workers (2 replicas)

-   **Image:** `bitnami/spark:3.5.0`
-   **Mode:** Worker
-   **Connects to:** `spark://spark-master:7077`
-   **Environment:**

    -   `SPARK_WORKER_MEMORY=2000m`
    -   `SPARK_DRIVER_MEMORY=2000m`

-   Scale up/down by adding more workers in `docker-compose.yml`.

---

### 3️⃣ Jupyter Notebook

-   **Image:** `jupyter/pyspark-notebook:latest`
-   **Port:** `8888 → localhost:8888`
-   **Volumes:**

    -   `./apps → /home/jovyan/work` (your notebooks and scripts)
    -   `./requirements.txt → /tmp/requirements.txt` (extra dependencies)

-   **Environment:**

    -   Configured to connect directly to the Spark cluster:

        ```
        SPARK_MASTER=spark://spark-master:7077
        SPARK_LOCAL_IP=jupyter
        SPARK_DRIVER_HOST=jupyter
        SPARK_DRIVER_BIND_ADDRESS=0.0.0.0
        ```

---

## ▶️ Usage

### 1. Start the cluster

```bash
docker compose up -d
```

### 2. Access UIs

-   **Spark Master UI:** [http://localhost:8080](http://localhost:8080)
-   **Jupyter UI:** [http://localhost:8888](http://localhost:8888)

Jupyter will give you a token URL (e.g. `http://127.0.0.1:8888/?token=...`).

---

## 📦 Installing Custom Python Packages

1. Add dependencies to `requirements.txt`.
2. Rebuild or restart Jupyter:

    ```bash
    docker exec -it jupyter pip install -r /tmp/requirements.txt
    ```

3. To make installs persistent, bake them into a custom Jupyter image or add them to `requirements.txt`.

---

## ⚡ Connecting to Spark in Jupyter

Example code in notebook:

```python
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("ExampleApp")
    .master("spark://spark-master:7077")
    .config("spark.executor.memory", "1G")
    .config("spark.driver.memory", "1G")
    .getOrCreate()
)

print(spark.version)
```

---

## ❗ Python Version Mismatch (Important)

-   Jupyter (`pyspark-notebook`) uses **Python 3.12**.
-   Spark workers (`bitnami/spark`) use **Python 3.11**.
-   This causes errors like:

    ```
    PySparkRuntimeError: [PYTHON_VERSION_MISMATCH]
    ```

### 🔧 Fix Options

1. **Quick fix:** Use Python **3.11 kernel** in Jupyter (pin version in Conda).
2. **Long-term fix:** Rebuild Spark worker images with Python **3.12** to match Jupyter.

---

## 🔑 Setting Jupyter Password Instead of Token

1. Create a password hash:

    ```bash
    python -c "from notebook.auth import passwd; print(passwd())"
    ```

    Example: `sha1:abcd1234...`

2. Add it to your Jupyter service in `docker-compose.yml`:

    ```yaml
    environment:
        - JUPYTER_TOKEN=
        - JUPYTER_PASSWORD=sha1:abcd1234...
    ```

3. Restart Jupyter:

    ```bash
    docker compose restart jupyter
    ```

Now you can log in with username `jovyan` and your chosen password.

---

## 🛑 Stopping the Cluster

```bash
docker compose down
```