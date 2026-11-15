import csv #
import random
from datetime import datetime, timedelta
from pathlib import Path

random.seed(42) #para reproducibilidad y consistencia de los resultados 

N_TICKETS = 10_000 # número de tickets a generar
INICIO = datetime(2025, 11, 1) # fecha de inicio para la generacion de tickets 
DIAS = 365 # numero de dias para generar tickets

SLA_HORAS = {"Alta": 4, "Media": 24, "Baja": 72}
CATEGORIAS = ["Hardware", "Software", "Red", "Accesos", "Impresoras"]
TECNICOS = ["Tecnico 1", "Tecnico 2", "Tecnico 3", "Tecnico 4"]
USUARIOS = [f"Usuario {n}" for n in range(1, 201)] # usuarios del 1 al 200
ESTADOS = ["Cerrado", "En proceso", "Abierto"]
FORMATO = "%Y-%m-%d %H:%M:%S" # formato de fecha y hora

def generar_ticket(ticket_id): # funcion para generar un ticket con datos aleatorios
    apertura = INICIO + timedelta(minutes=random.randint(0, DIAS * 24 * 60)) # se genera una fecha de apertura aleatoria dentro de lo establecido por INICIO y DIAS 
    prioridad = random.choices(list(SLA_HORAS), weights=[2, 5, 3])[0] # se asigna una prioridad aleatoria con pesos para que haya mas tickets de prioridad media y baja que alta
    estado = random.choices(ESTADOS, weights=[80, 12, 8])[0] 

    if estado == "Cerrado":
        horas = random.uniform(0.5, SLA_HORAS[prioridad] * 1.6)
        cierre = (apertura + timedelta(hours=horas)).strftime(FORMATO)
    else:
        cierre = ""

    return {
        "ticket_id": ticket_id,
        "fecha_apertura": apertura.strftime(FORMATO),
        "fecha_cierre": cierre,
        "usuario": random.choice(USUARIOS),
        "tecnico": random.choice(TECNICOS),
        "categoria": random.choice(CATEGORIAS),
        "prioridad": prioridad,
        "estado": estado,
        "reabierto": 1 if random.random() < 0.07 else 0,
    }


def ensuciar(filas): # funcion para ensuciar los datos generados y simular errores humanos y problemas de calidad de datos
    cantidad = int(len(filas) * 0.03) # se calcula el 3% de la cantidad de filas para ensuciar
    for fila in random.sample(filas, cantidad): # se selecciona una muestra aleatoria de filas para ensuciar
        tipo = random.choice(["fecha_invalida", "cierre_antes", "categoria_sucia", "vacio", "duplicados"]) # se selecciona un tipo de ensuciamiento al azar
        if tipo == "fecha_invalida": # se asigna una fecha de apertura invalida a la fila seleccionada 
            fila["fecha_apertura"] = "31/02/2026" # se muestra un ejemplo de fecha invalida para ensuciar los datos
        elif tipo == "cierre_antes": # se asigna una fecha de cierre antes de la fecha de apertura a la fila seleccionada
            fila["fecha_cierre"] = "2025-10-31 12:00:00" # se muestra un ejemplo de fecha de cierre antes de la fecha de apertura para ensuciar datos
        elif tipo == "categoria_sucia": # se asigna una categoria sucia a la fila seleccionada
            fila["categoria"] = "Hardware/software" # se muestra un ejemplo de categoria sucia para ensuciar datos
        elif tipo == "vacio": # se asigna un valor vacio a la fila seleccionada
            fila["usuario"] = "" # se muestra un ejemplo de valor vacio
        elif tipo == "duplicados": # se asigna un ticket_id duplicado a la fila seleccionada 
            fila["ticket_id"] = random.choice(filas)["ticket_id"]
    return filas


def main(): # funcion principal para generar los tickets y guardarlos en un archivo CSV
    filas = [generar_ticket(i) for i in range(1, N_TICKETS + 1)] # generar tickets y guardarlos en una lista de diccionarios
    filas = ensuciar(filas) # ensuciar los datos generados para simular errores humanos y problemas de calidad de datos 

    ruta = Path(__file__).parent / "tickets.csv" # ruta del archivo CSV donde se guardan los tickets generados
    with open(ruta, "w", newline="", encoding="utf-8") as f:
        escritor = csv.DictWriter(f, fieldnames=filas[0].keys())
        escritor.writeheader()
        escritor.writerows(filas)
    print(f"Listo: {len(filas)} filas en {ruta}")


if __name__ == "__main__": # si el script se ejecuta directamente, se llama a la funcion main para generar los tickets
    main()

