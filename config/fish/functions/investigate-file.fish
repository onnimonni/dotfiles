# Help figure out what data looks like
function investigate-file --description 'Shows human readable contents of many large files'
  set -l file_path $argv[1]
  # Check if the file starts with http(s)://
  switch $file_path
  case 'https://*parquet' 'https://*csv'
    duckdb -c """
      SUMMARIZE FROM '$file_path';
    """
    return
  case 'https://*json'
    duckdb -c """
      SUMMARIZE FROM read_json_auto('$file_path', maximum_object_size=3e8, sample_size=100_000);
    """
    return
  end

  set -l file_type_info (file -b $file_path)
  # Branch based on the file type information
  switch (file -b $file_path)
  case '*Zip archive data*' '*gzip compressed data*'
    # TODO: There seems to be more recent version of atool: https://github.com/z3ntu/atool
    # TODO: Check if this atool can be replaced in homebrew
    # TODO: --quiet option is not working with zip files:
    # $ atool -q -l swagger.zip
    # Length      Date    Time    Name
    # ---------  ---------- -----   ----
    # 261775  03-23-2025 12:21   swagger.json
    # ---------                     -------
    # 261775                     1 file
    atool -l $file_path

    # TODO: if you can easily check that the archive contains just one file
    # you can use `atool -c` to extract it and do further analysis
  case '*JSON data*' # Matches if "CSV text" is in the file type string
    # For small files, use jq to pretty print
    if test (du -k $file_path | awk '{print $1}') -lt 20
      echo "$file_path: JSON"
      jq . $file_path
    else
      echo "$file_path: JSON (too large to pretty print)"
      duckdb -c """
        SELECT * EXCLUDE(avg,std,q25,q50,q75) REPLACE(LEFT(min, 60) as min, LEFT(max, 60) as max)
        FROM (
          SUMMARIZE (
            FROM read_json_auto('$file_path', maximum_object_size=3e8, sample_size=100_000)
          )
        );
        FROM read_json_auto('$file_path', maximum_object_size=3e8, sample_size=100_000);
      """
    end
  case '*CSV text*' # Matches if "CSV text" is in the file type string
    # TODO: Check file encoding like in the bank statements which don't use UTF-8
    echo "$file_path: CSV"
    duckdb -c """
      SELECT * EXCLUDE(avg,std,q25,q50,q75) REPLACE(LEFT(min, 65) as min, LEFT(max, 65) as max)
      FROM (
        SUMMARIZE (
          FROM read_csv_auto('$file_path')
        )
      );
      FROM read_csv_auto('$file_path');
    """
  case '*SQLite*' # Matches if "SQLite" is in the file type string
    echo "This is an SQLite file: $file_type_info"
    duckdb $file_path -c """
      SELECT * EXCLUDE(database_name, database_oid, schema_name, schema_oid, table_oid, internal, temporary, sql)
      FROM duckdb_tables()
      ORDER BY estimated_size DESC;

      SET VARIABLE tables_sorted_by_size = (
          SELECT ARRAY_AGG(table_name ORDER BY estimated_size DESC)
          FROM duckdb_tables()
      );

      -- FIXME: This might scan the whole table again
      SELECT getvariable('tables_sorted_by_size')[1] as table_name,* EXCLUDE(q25,q50,q75) REPLACE(LEFT(min, 40) as min, LEFT(max, 40) as max) FROM (
        SUMMARIZE FROM sqlite_scan('$file_path', getvariable('tables_sorted_by_size')[1])
      );
      SELECT getvariable('tables_sorted_by_size')[2] as table_name,* EXCLUDE(q25,q50,q75) REPLACE(LEFT(min, 40) as min, LEFT(max, 40) as max) FROM (
        SUMMARIZE FROM sqlite_scan('$file_path', getvariable('tables_sorted_by_size')[2])
      );
    """
  case '*' # Default case for any other file type
    echo $file_type_info
  end
end
