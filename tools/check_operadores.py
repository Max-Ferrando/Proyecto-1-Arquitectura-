import glob, re, os, sys

# Modulos que SI pueden usar Verilog conductual (interfaz secuencial con la placa)
EXENTOS = {'debounce.v', 'fsm_control.v'}

# (etiqueta, regex)
PROHIBIDOS = [
    ('+',   r'\+'),
    ('-',   r'(?<![-\w])-(?![-])'),
    ('<<',  r'<<'),
    ('>>',  r'>>'),
    ('<=',  r'<='),
    ('>=',  r'>='),
    ('<',   r'(?<![<=])<(?![<=])'),
    ('>',   r'(?<![>=-])>(?![>=])'),
    ('?:',  r'\?'),
    ('if',  r'\bif\b'),
    ('case', r'\bcase\b'),
]

def limpiar(txt):
    txt = re.sub(r'/\*.*?\*/', ' ', txt, flags=re.S)   # comentarios de bloque
    txt = re.sub(r'//[^\n]*', ' ', txt)                # comentarios de linea
    return txt

hallazgos = 0
for ruta in sorted(glob.glob(os.path.join(sys.argv[1], '*.v'))):
    nombre = os.path.basename(ruta)
    with open(ruta, encoding='utf-8', errors='replace') as f:
        lineas = f.readlines()
    texto = limpiar(''.join(lineas))
    lineas_limpias = texto.split('\n')

    for etiqueta, patron in PROHIBIDOS:
        for i, linea in enumerate(lineas_limpias, 1):
            if re.search(patron, linea):
                marca = '  (exento)' if nombre in EXENTOS else '  <-- REVISAR'
                print(f'{nombre}:{i}  operador "{etiqueta}"{marca}')
                print(f'      {linea.strip()}')
                if nombre not in EXENTOS:
                    hallazgos += 1

print()
if hallazgos == 0:
    print('OK: ningun operador prohibido en los modulos no exentos.')
else:
    print(f'ATENCION: {hallazgos} ocurrencia(s) a revisar.')
