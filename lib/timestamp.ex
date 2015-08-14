defmodule Timestamp do
  use Timex

  def now do
    {:ok, ts} = Date.local |> DateFormat.format "{ISOdate} {ISOtime}"
    ts
  end

end
