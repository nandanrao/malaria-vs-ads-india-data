import argparse
import json
from os.path import join

import orjson

from translation.translation import get_all_forms, get_translators


def main(survey_name, out):
    db_conf = {
        "db": "chatroach",
        "user": "chatreader",
        "host": "localhost",
        "port": "5432",
        "password": None,
    }

    forms = list(get_all_forms([survey_name], db_conf))
    translators = get_translators(db_conf, forms, "http://localhost:1323")

    with open(join(out, "translators.json"), "w") as f:
        json.dump(translators, f)

    with open(join(out, "forms.json"), "wb") as f:
        f.write(orjson.dumps(forms))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Generates translation json file. "
        "Requires direct access to database and formcentral"
    )
    parser.add_argument("survey_name", type=str, help="name of the survey")
    parser.add_argument(
        "outfile", type=str, help="outfile to save translators json file"
    )
    args = parser.parse_args()
    main(args.survey_name, args.outfile)
