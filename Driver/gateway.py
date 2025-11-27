#!/usr/bin/env python3


#
#  Copyright 2022-2024 Felix Garcia Carballeira, Diego Carmarmas Alonso, Alejandro Calderon Mateos
#
#  This file is part of CREATOR.
#
#  CREATOR is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  CREATOR is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with CREATOR.  If not, see <http://www.gnu.org/licenses/>.
#


from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS, cross_origin
import subprocess, os, signal
import logging
import webbrowser
import re

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
process_holder = {}


#### (*) Cleaning functions
def do_fullclean_request(request):
    """Full clean the build directory"""
    try:
        req_data = request.get_json()
        target_device = req_data["target_port"]
        req_data["status"] = ""
        error = 0
        # flashing steps...
        if error == 0:
            do_cmd_output(req_data, ["make", "-C", "./main", "clean"])
        if error == 0:
            req_data["status"] += "Full clean done.\n"
    except Exception as e:
        req_data["status"] += str(e) + "\n"
    return jsonify(req_data)


def do_eraseflash_request(request):
    """Erase flash the target device"""
    try:
        req_data = request.get_json()
        target_device = req_data["target_port"]
        target_loc = req_data["target_location"]
        req_data["status"] = ""
        # flashing steps...
        route = target_loc + "/*"

        error = 0
        if error == 0:
            command = f"rm -rvf {route}"

            error = do_cmd_output(
                req_data,
                ["ssh", target_device, command],
            )
        if error == 0:
            req_data["status"] += "Erase flash done.\n"
        else:
            logging.error("Error" + error)

    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# (1) Get form values
def do_get_form(request):
    try:
        return send_file("gateway.html")
    except Exception as e:
        return str(e)


# Adapt assembly file...


def creator_build(file_in, file_out):
    try:
        with open(file_in, "rt") as fin, open(file_out, "wt") as fout:
            # write header
            fout.write(".text\n")
            fout.write(".type main, @function\n")
            fout.write(".globl main\n\n")
            fout.write('.include "ecall_macros.s"\n\n')

            for line in fin:
                fout.write(line)

        return 0
    except Exception as e:
        print("Error adapting assembly file: ", str(e))
        return -1


def do_cmd(req_data, cmd_array, name_process=None):
    try:
        result = subprocess.run(cmd_array, capture_output=False, timeout=60)
        if name_process == "gdbgui" or name_process == "monitor":
            process_holder[name_process] = result
    except:
        pass

    if result.stdout != None:
        req_data["status"] += result.stdout.decode("utf-8") + "\n"
    if result.returncode != None:
        req_data["error"] = result.returncode

    return req_data["error"]


def do_cmd_output(req_data, cmd_array):
    try:
        result = subprocess.run(
            cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60
        )
    except Exception as e:
        logging.error("Error: " + str(e))
        # Opcional: asignar error en req_data para indicar fallo
        req_data["error"] = -1
        req_data["status"] = req_data.get("status", "") + f"Exception: {str(e)}\n"
        return req_data["error"]

    if result.stdout is not None:
        req_data["status"] = (
            req_data.get("status", "") + result.stdout.decode("utf-8") + "\n"
        )

    if result.returncode is not None:
        req_data["error"] = result.returncode
    else:
        req_data["error"] = 0  # Por si no hay código de error

    return req_data["error"]


# (2) Flasing assembly program into target board
def do_flash_request(request):
    try:
        req_data = request.get_json()
        target_device = req_data["target_port"]
        target_board = req_data["target_board"]
        target_loc = req_data["target_location"]
        asm_code = req_data["assembly"]
        req_data["status"] = ""
        user, host = target_device.split("@")
        if "gdbgui" in process_holder:
            logging.debug("Killing GDBGUI")
            kill_all_processes(host, user, "gdbgui")
            process_holder.pop("gdbgui", None)

        # create temporal assembly file
        text_file = open("tmp_assembly.s", "w")
        ret = text_file.write(asm_code)
        text_file.close()

        # transform th temporal assembly file
        error = creator_build("tmp_assembly.s", "main/program.s")
        if error != 0:
            req_data["status"] += "Error adapting assembly file...\n"
        # flashing steps...
        if error == 0:
            # Compile: CHECK HOW SAIL DOES THIS
            error = do_cmd(
                req_data,
                ["make", "-C", "./main"],
            )
        if error == 0:
            # Send code: CONFIGURE IP AND USER
            error = do_cmd(
                req_data,
                [
                    "scp",
                    "-r",
                    "main",
                    f"{target_device}:{target_loc}",
                ],
            )

    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# (3) Run program into the target board
def do_monitor_request(request):
    try:
        req_data = request.get_json()
        target_device = req_data["target_port"]
        target_loc = req_data["target_location"]
        req_data["status"] = ""
        route = target_loc + "/main/program"
        do_cmd(req_data, ["ssh", target_device, route], "program")

    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# (4) Flasing assembly program into target board
def do_job_request(request):
    try:
        req_data = request.get_json()
        target_device = req_data["target_port"]
        target_board = req_data["target_board"]
        asm_code = req_data["assembly"]
        req_data["status"] = ""
    # TODO: Decisions remote lab
    except:
        pass

    return jsonify(req_data)


# (5) Stop flashing
def do_stop_flash_request(request):
    try:
        req_data = request.get_json()
        req_data["status"] = ""
        do_cmd(req_data, ["pkill", "idf.py"])

    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# ()Kill debug processes
def kill_all_processes(host, user, process_name):
    if not process_name:
        logging.error("El nombre del proceso no puede estar vacío.")
        return 1
    print(process_name)
    # Comando remoto para matar procesos por nombre usando pkill -9 (kill -9)
    remote_kill_cmd = f"pkill -9 -f {process_name}"
    ssh_cmd_kill = ["ssh", f"{user}@{host}", remote_kill_cmd]

    try:
        result = subprocess.run(
            ssh_cmd_kill, capture_output=True, text=True, timeout=10, check=False
        )

        if result.returncode != 0:
            # pkill devuelve 1 si no encontró procesos, no es un error grave en general
            if result.returncode == 1:
                logging.debug(f"Not process founded '{process_name}' in {host}.")
                return 1
            logging.error(
                f"Error killing process '{process_name}' in {host}. Output: {result.stderr.strip()}"
            )
            return result.returncode

        logging.info(f"Process '{process_name}' eliminated in {host}.")
        return 0

    except subprocess.TimeoutExpired as e:
        logging.error(f"Time exceded: {e}")
        return 1

    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        return 1


# (6) Start Debugging
def do_debug(request):
    req_data = request.get_json()
    req_data["status"] = ""
    target_device = req_data["target_port"]
    target_loc = req_data["target_location"]
    user, host = target_device.split("@")

    # if "gdbgui" in process_holder:
    #     logging.debug("Killing GDBGUI")
    #     kill_all_processes("10.117.129.219","orangepi","gdbgui")
    #     process_holder.pop("gdbgui", None)
    kill_all_processes(host, user, "gdbgui")

    original_route = os.getcwd()
    main_route = os.path.join(original_route, "main")
    main_route_destino = target_loc + "/main"

    url = f"http://{host}:5000/"
    webbrowser.open_new_tab(url)

    try:
        cmd = (
            f"source /home/orangepi/gdbgui-venv/bin/activate && "
            f"gdbgui {target_loc}/main/program --host 0.0.0.0 --port 5000 --no-browser "
            f"-g \"gdb -ex 'set substitute-path {main_route} {main_route_destino}' -x {target_loc}/main/script.gdb\""
        )
        do_cmd(req_data, ["ssh", target_device, cmd])
    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# (7) Stop monitor and debug
def do_stop_monitor_request(request):
    """Shortcut for stopping Monitor / debug"""
    try:
        req_data = request.get_json()
        req_data["status"] = ""
        target_device = req_data["target_port"]
        user, host = target_device.split("@")
        print("Killing Monitor")
        error = kill_all_processes(host, user, "program")
        if error == 0:
            error = kill_all_processes(host, user, "gdbgui")
        if error == 0:
            req_data["status"] += "Process stopped\n"

    except Exception as e:
        req_data["status"] += str(e) + "\n"

    return jsonify(req_data)


# Setup flask and cors:
app = Flask(__name__)
cors = CORS(app)
app.config["CORS_HEADERS"] = "Content-Type"


# (1) GET / -> send gateway.html
@app.route("/", methods=["GET"])
@cross_origin()
def get_form():
    return do_get_form(request)


# (2) POST /flash -> flash
@app.route("/flash", methods=["POST"])
@cross_origin()
def post_flash():
    try:
        shutil.rmtree("build")
    except Exception as e:
        pass

    return do_flash_request(request)


# (3) POST /monitor -> flash
@app.route("/monitor", methods=["POST"])
@cross_origin()
def post_monitor():
    return do_monitor_request(request)


# (4) POST /job -> flash + monitor
@app.route("/job", methods=["POST"])
@cross_origin()
def post_job():
    return do_job_request(request)


# (5) POST /stop -> cancel
@app.route("/stop", methods=["POST"])
@cross_origin()
def post_stop_flash():
    return do_stop_flash_request(request)


# (6) POST /debug -> debug
@app.route("/debug", methods=["POST"])
@cross_origin()
def post_debug():
    return do_debug(request)


# (7) Stop monitor
@app.route("/stopmonitor", methods=["POST"])
@cross_origin()
def post_stop_monitor():
    return do_stop_monitor_request(request)


# (*) POST /fullclean -> clean build directory
@app.route("/fullclean", methods=["POST"])
@cross_origin()
def post_fullclean_flash():
    return do_fullclean_request(request)


@app.route("/eraseflash", methods=["POST"])
@cross_origin()
def post_erase_flash():
    return do_eraseflash_request(request)


# Run
app.run(host="0.0.0.0", port=8080, use_reloader=False, debug=True)
