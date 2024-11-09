{xml, _} = :xmerl_scan.file("Alarm_Mapping_Routine_RLL.L5X")

data =
  :xmerl_xpath.string(
    '/RSLogix5000Content/Controller/Programs/Program/Routines/Routine/RLLContent/Rung/Text/text()',
    xml
  )
  |> Enum.map(fn x ->
    {_, _, _, _, rung, _} = x
    to_string(rung)
  end)
  |> Enum.filter(fn x ->
    not String.contains?(x, ["NOP()", "AFI()"])
  end)
  |> Enum.map(fn x ->
    [_, tag, _, addr, _] = String.split(x, ["(", ")"])

    [{_, _, _, _, tag_desc, _}] =
      :xmerl_xpath.string(
        '/RSLogix5000Content/Controller/Tags/Tag[@Name="#{tag}"]/Description/text()',
        xml
      )

    [_, tag_desc, _] = String.split(to_string(tag_desc), "\n")

    "#{tag}, #{tag_desc}, #{addr}\n"
  end)
  |> IO.inspect()

File.write("tag.csv", data)
