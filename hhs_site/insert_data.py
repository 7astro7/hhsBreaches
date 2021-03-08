from map_breaches.models import Breach
import pandas as pd
import os

# case was merged with another
known_null = "Valperaiso Fire Department"


def make_df(archive: bool = False) -> pd.DataFrame:
    path_list = [
        "data_collection",
        "data_downloads",
    ]
    if archive:
        path_list.append("archive")
    else:
        path_list.append("currently_under_investigation")
    stem = os.path.sep.join(path_list)
    path = stem + os.path.sep + "breach_report.csv"
    data = pd.read_csv(
        path,
        true_values=[
            "Yes",
            "yes",
        ],
        false_values=[
            "No",
            "no",
        ],
        parse_dates=[
            "Breach Submission Date",
        ],
    )
    data["archive"] = (archive,) * len(data)
    data.rename(columns=make_new_col_names(data), inplace=True)
    data["web_description"] = data["web_description"].astype("str")
    if archive:
        name_col = data.name_of_covered_entity
        drop_index = data[name_col == known_null].index[0]
        data.drop(index=drop_index, inplace=True)
    return data.convert_dtypes()


def make_new_col_names(df: pd.DataFrame) -> dict:
    col_names = df.columns.tolist()
    make_name = lambda i: i.lower().replace(" ", "_")
    return dict(zip(col_names, map(make_name, col_names)))


def insert_rows(df: pd.DataFrame):
    for row in range(len(df)):
        Breach(**dict(df.iloc[row, :])).save()


# insert_rows(make_df(archive = True))
# insert_rows(make_df())
