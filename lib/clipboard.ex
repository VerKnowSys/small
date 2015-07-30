defmodule Clipboard do

def put text do
  case System.cmd "sh", ["-c", "echo $0 | pbcopy", "#{text}"] do
    {results, 0} ->
      {:ok, "Copied successfully"}

    {_, res} ->
      {:error, "Can't copy to clipboard. Error: #{res}"}
  end
end

end
