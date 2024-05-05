defmodule Timestamp do
  @doc """
  Returns system time in ųs
  """
  @spec now_unix() :: integer()
  def now_unix(), do: :os.system_time()

  @doc """
  Convert timestamp to String
  """
  @spec now() :: String.t
  def now do
    timestamp_converted = System.convert_time_unit(now_unix(), :native, :microsecond)
    full_date = DateTime.to_string(DateTime.from_unix!(timestamp_converted, :microsecond))
    List.first(String.split(full_date, "."))
  end
end
