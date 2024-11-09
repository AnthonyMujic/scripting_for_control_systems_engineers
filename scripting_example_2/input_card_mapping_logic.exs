rungs =
  File.read!("input_card_mapping.csv")
  |> String.split("\n")
  |> Enum.filter(fn x ->
    not (String.length(x) == 0)
  end)
  |> Enum.map(fn x ->
    [input, output] = String.split(x, ",")
    "<Rung Type=\"N\"><Text><![CDATA[XIC(#{input})OTE(#{output});]]></Text></Rung>\n"
  end)
  |> IO.inspect()

File.write("./input_card_mapping.txt", rungs)
