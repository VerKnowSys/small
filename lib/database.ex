use Amnesia


defdatabase Database do
  # this is just a forward declaration of the table, otherwise you'd have
  # to fully scope User.read in History functions
  deftable User


  deftable History, [:user_id, :content, :timestamp, :file], type: :bag do
    @type t :: %History{user_id: integer, content: String.t, timestamp: String.t, file: String.t}

    # this defines a helper function to fetch the user from a History record
    def user self do
      User.read self.user_id
    end

  end


  deftable User, [{ :id, autoincrement }, :name], type: :set, index: [:name] do
    @type t :: %User{id: non_neg_integer, name: String.t}

    def add_history self, content, file do
      %History{user_id: self.id, content: content, timestamp: Timestamp.now, file: file} |> History.write
    end

    def histories self do
      History.read self.id
    end

  end
end
