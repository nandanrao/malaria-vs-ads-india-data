import json

import pandas as pd
from toolz import pipe
from vlab_prepro import Preprocessor, parse_number

from translation.translation import translate_responses


def load(name):
    forms = pd.read_csv(f"raw/forms-{name}.csv")
    rdf = pd.read_csv(f"raw/responses-{name}.csv")
    return forms, rdf


def load_json(path):
    with open(path) as f:
        d = json.load(f)
    return d


def format_round_a(rdf, forms):
    p = Preprocessor()

    df = pipe(
        rdf,
        p.add_form_data(forms),
        p.add_metadata(["clusterid", "startTime"]),
        p.add_duration,
        p.add_time_indicators(["week", "month"]),
        p.count_invalid,
        p.keep_final_answer,
        p.drop_users_without("clusterid"),
        p.drop_duplicated_users(["wave"]),
    )

    translators = load_json("raw/translation/translators.json")
    forms_json = load_json("raw/translation/forms.json")

    translated_responses = translate_responses(
        forms_json, translators, df.to_dict(orient="records")
    )

    df = pd.DataFrame(translated_responses)
    df = df[~df.question_ref.isna()]
    df = pipe(df,
              p.pivot("translated_response"),
              # p.map_columns(["age", "familymembers"], parse_number),
              )

    return df


def generate_round_a(name):
    forms, rdf = load(name)
    df = format_round_a(rdf, forms)
    df.to_csv(f"final/responses/{name}.csv", index=False)


def generate(name):
    forms, rdf = load(name)

    p = Preprocessor()
    df = pipe(
        rdf,
        p.add_form_data(forms),
        p.add_metadata(["stratumid"]),
        p.add_duration,
        p.add_time_indicators(["week", "month"]),
        p.count_invalid,
        p.keep_final_answer,
        p.drop_users_without("stratumid"),
        p.drop_duplicated_users(["wave"]),
        p.pivot("translated_response"),
        p.map_columns(["age", "familymembers"], parse_number),
    )

    df.to_csv(f"final/responses/{name}.csv", index=False)


if __name__ == "__main__":
    generate_round_a("malaria-no-more")

    for name in ["MNM", "1-shot"]:
        generate(name)
