#!/bin/sh
set -e

# Check if env exists, otherwise create it
if ! conda env list | grep -q "^spark "; then
    echo "Creating conda env 'spark'..."
    conda create -n spark python=3.11 -y
    conda run -n spark pip install -r /tmp/requirements.txt
    conda run -n spark pip install python-lsp-server
    echo "All dependencies installed successfully."
    echo "Env Created."
else
    echo "Conda env 'spark' already exists."

fi

# Run Jupyter (the container’s default CMD)
/usr/local/bin/start-notebook.sh "$@"