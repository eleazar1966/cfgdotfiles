---
name: tryton-development
description: "Trigger: tryton module, account_ve, PUC, chart of accounts, tryton development, tryton style. Strict Tryton coding conventions from official guidelines."
license: Apache-2.0
metadata:
  author: "gentle-orchestrator"
  version: "2.0"
---

# Tryton Development — Strict Coding Conventions

> Fuente oficial: https://www.tryton.org/develop/guidelines/code
> Documentación módulos: https://docs.tryton.org/latest/server/topics/modules/index.html

## Activation Contract

Cargar este skill al trabajar con módulos Tryton: `account_ve`, `tryton.cfg`, `account_chart_*.xml`, `__init__.py` con `Pool.register`, o cualquier Python bajo `trytond/modules/`. Anula defaults genéricos de Python donde Tryton diverge.

## Hard Rules

### Python Style (PEP 8 + PEP 257 con excepciones Tryton)

- **4 espacios** de indentación. NO tabs.
- **Sin límite de 80 columnas** (Tryton explícitamente no lo aplica en XML ni Python).
- **Sin límite de columnas en XML** (explícito en guidelines).
- Flake8 check: `ignore=E123,E124,E126,E128,E741,W503`
- Imports con isort: `-m VERTICAL_GRID -p trytond`
- `trytond` y `trytond_gis` son `known_first_party` en `.isort.cfg`.

**Breaking lines:**
- 4 espacios por par de brackets (no 2, no 8).
- Preferir paréntesis `()` sobre backslash `\`.
- Preferir break tras abrir paréntesis.

**Strings:**
| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Natural language (texto usuario) | `"doble comilla"` | `"Invoice"`, `"Party Name"` |
| Symbol-like (código, IDs) | `'simple comilla'` | `'account.invoice'`, `'pending'` |
| Docstrings multi-línea | `"""triple doble"""` | `"""Summary.\n\nDetail."""` |

### Naming (estructura TESIS — de general a específico)

```
Primera parte = función general
Segunda parte = sub-funciones más específicas
```

Ejemplo: `account.account.template` → account (general) → account.template (específico)
Ejemplo: `sale.sale` → sale (general) → sale (la venta en sí)

| Elemento | Estilo | Ejemplo |
|----------|--------|---------|
| Model `__name__` | dot.notation (general→específico) | `account.account.template` |
| Clase Python | CamelCase | `AccountTemplate` |
| Método/función | snake_case | `create_account()` |
| Campo | snake_case | `party_required` |
| Módulo Tryton | snake_case (una palabra descriptiva) | `account_ve` |
| Constante | UPPER_CASE | `MAX_DEPTH = 3` |
| Archivo Python | snake_case | `account_ve.py` |
| Archivo XML | snake_case | `account_chart_ve.xml` |
| XML ID | snake_case | `account_template_1_0_0_ve` |

### Imports (orden estricto, separados por línea en blanco)

```python
# 1. Python stdlib
import os
from datetime import date

# 2. Terceros (casi no se usan en Tryton core)
# (vacio)

# 3. trytond (known_first_party)
from trytond.model import ModelSQL, ModelView, fields
from trytond.pool import Pool
from trytond.pyson import If, Bool, Eval

# 4. Módulo local
from .common import PeriodMixin
```

### Module Structure

```
module_name/
├── __init__.py          # Pool.register()
├── tryton.cfg           # [tryton] version, depends, xml, [register]
├── setup.py             # Packaging (cookiecutter template)
├── *.py                 # Modelos
├── *.xml                # Datos + vistas
├── view/                # Vistas XML separadas (opcional)
├── locale/              # Traducciones .po
│   └── es.po
├── tests/               # test_*.py + scenario_*.rst
│   ├── __init__.py
│   └── test_module.py
├── doc/                 # Documentación RST (Sphinx)
│   ├── index.rst
│   ├── setup.rst
│   └── usage.rst
└── icons/               # Iconos del módulo
```

### tryton.cfg

```ini
[tryton]
version=8.0.x
depends:
    account
    company
    party
    currency
    country
extras_depend:
    sale
xml:
    account_chart_ve.xml

[register]
model:
    # (opcional — modelos a registrar, relativos al módulo)
    party.PartyExtension
wizard:
    # (opcional)
    account_ve.CreateChart
```

**Keys de `[tryton]`**: `version`, `depends`, `extras_depend`, `xml`, `include_dirs`, `test_include_dirs`
**Secciones opcionales**: `[register]` con keys `model`, `wizard`, `report`; `[register_mixin]`

### XML - Tags y atributos oficiales

**`<tryton>`**: Root tag obligatorio.

**`<data>`**: Agrupa datos. Atributos:
- `noupdate` — no actualizar registros existentes
- `depends` — solo importar si todos los módulos en la lista están activos
- `grouped` — crear registros al final con llamada agrupada
- `language` — solo importar si el idioma es traducible

**`<record model="..." id="...">`**: Crear registro. Atributo `search` (dominio para buscar registro existente en lugar de crear).

**`<field name="...">`**: Asignar valor a campo. Atributos:
- `search` — dominio para buscar valor en campos relación
- `ref` — XML ID del registro relacionado (`modulo.xml_id` si es de otro módulo)
- `eval` — código Python evaluado. Variables disponibles: `time`, `version`, `ref()`, `Decimal`, `datetime`, `pyson`, `path`
- `depends` — solo asignar si los módulos están activos

**Nota**: El contenido del field es STRING. Para otros tipos usar `eval`.

**`<menuitem>`**: Atajo para crear menús. Atributos: `id`, `name`, `icon`, `sequence`, `parent`, `action`, `groups`, `active`.

### XML - Vistas

Archivos de vista usando CDATA para el `arch`:
```xml
<record model="ir.ui.view" id="party_view_tree">
    <field name="model">party.party</field>
    <field name="type">tree</field>
    <field name="arch">
        <![CDATA[
        <tree string="Parties">
            <field name="name"/>
            <field name="code"/>
        </tree>
        ]]>
    </field>
</record>
```

Tipos: `form`, `tree`, `graph`, `search`, `board`.

### XML Style (oficial Tryton)

- 4 espacios de indentación
- Sin límite de 80 columnas
- Opening tag: en una línea, O un atributo por línea

### Modelos Python

```python
from trytond.model import ModelSQL, ModelView, fields
from trytond.pool import Pool

class AccountTemplate(ModelSQL, ModelView):
    "Account Template"
    __name__ = 'account.account.template'

    name = fields.Char("Name", required=True)
    code = fields.Char("Code")
    type = fields.Many2One('account.account.type.template', "Type")
    parent = fields.Many2One('account.account.template', "Parent")
    childs = fields.One2Many('account.account.template', 'parent', "Children")
    closed = fields.Boolean("Closed",
        states={'invisible': ~Eval('type')})

    @classmethod
    def __setup__(cls):
        super().__setup__()
        cls._order.insert(0, ('code', 'ASC'))

    def get_rec_name(self, name):
        pool = Pool()
        # ... al inicio del método, tras docstring
```

**Reglas:**
- Docstrings y comments SIEMPRE.
- `Pool().get('model.name')` al inicio del método (tras docstring).
- Nunca pasar keyword arguments como positional.
- `assert` para toda asunción.
- `super()` siempre al extender.
- Alterar resultado existente, no construir nuevo.
- `@classmethod` para métodos de clase.

### Dominios (PYSON)

```python
from trytond.pyson import If, Bool, Eval

domain=[
    If(Eval('parent') & Eval('_parent_parent.type'),
        ('id', '=', Eval('_parent_parent.type')),
        ()),
    ]
```

Operadores: `&` (AND), `|` (OR), `~` (NOT), `Bool()` (coerción booleana), `Eval()` (valor del campo), `If()` (condicional), `Id()` (XML ID a DB ID).

### Charts de Cuentas (reglas estrictas)

1. **UN solo root**: `parent=None`, `closed=True`, con `type=<root_type>`.
2. **Agrupadoras** (tienen hijos en XML): **NO tienen `type`**. Rompe la cadena de validación `_parent_parent.type`.
3. **Hojas** (sin hijos): sí tienen `type`.
4. Nivel 1 (hijos del root) PUEDEN tener `type` porque `_parent_parent.parent = None` (el root no tiene padre) → la condición del dominio falla.
5. `reconcile=True` siempre acompañado de `party_required=True`.
6. Tipos de resultado: `expense=True` o `revenue=True` obligatorio.
7. Todos los tipos: `sequence` obligatorio para orden.
8. `closed=True` en cuentas estructurales (no reciben asientos).

### Pool Registration

```python
# __init__.py — Registro simple (todo el módulo)
from trytond.pool import Pool

def register():
    Pool.register(
        module='account_ve',
        type_='model',
    )

# Con clases específicas
def register():
    Pool.register(
        AccountTemplate,
        AccountTypeTemplate,
        module='account_ve',
        type_='model',
    )
```

### Validaciones y Extensiones

```python
# Extender modelo existente (NUNCA modificar core)
from trytond.pool import PoolMeta

class Party(metaclass=PoolMeta):
    __name__ = 'party.party'

    new_field = fields.Char("New Field")

    @classmethod
    def __setup__(cls):
        super().__setup__()

# assert para invariantes
assert self.parent is None, "Solo root puede crear cuentas"
```

### Tests

- `test_*.py` para unit tests.
- `scenario_*.rst` para tests de flujo (Proteus).
- Usar `activate_modules()` para bootstrap.
- Usar `Wizard()` de Proteus para probar wizards.
- Cobertura de 100% en features nuevas.

### Commit Messages

```
Título corto con mayúscula inicial (imperativo)

Cuerpo explicando QUÉ y POR QUÉ.
Máximo 80 caracteres por línea en cuerpo.
- Bullet points con guión si aplica.

Signed-off-by: Name <email>
```

## Decision Gates

| Situación | Acción |
|-----------|--------|
| Agregar campo a modelo core | Usar `PoolMeta`, NUNCA modificar core |
| Extender método existente | `super()` siempre, alterar resultado |
| Nueva funcionalidad en chart | `type` solo en root y hojas |
| Duda sobre naming | Usar prefijo del módulo si no es obvio |
| Duda sobre dónde poner código | Un solo módulo por deploy (recomendación B2CK) |
| Organizar modelos internamente | Un archivo por modelo core Tryton (`party.py`, `sale.py`) |

## References

- https://www.tryton.org/develop/guidelines/code — Coding Guidelines oficiales
- https://docs.tryton.org/latest/server/topics/modules/index.html — Documentación de módulos
- https://docs.tryton.org/latest/server/topics/domain.html — Dominios
- https://docs.tryton.org/latest/server/topics/pyson.html — PYSON
- flake8: `ignore=E123,E124,E126,E128,E741,W503`
- isort: `-m VERTICAL_GRID -p trytond`
