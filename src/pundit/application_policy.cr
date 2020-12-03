# The default Pundit policy that all other policies should inherit from.
#
# Should you with to update the default policy definitions, run `lucky pundit.init` and override where needed.
abstract class ApplicationPolicy(T)
  getter user
  getter record

  # A policy takes in a user that might be nil, as well as an object that may be nil.
  #
  # These are available in all policy check methods for access.
  def initialize(@user : User?, @record : T? = nil)
  end

  # Whether or not the `Index` action can be accessed
  def index?
    false
  end

  # Whether or not the `Show` action can be accessed
  def show?
    false
  end

  # Whether or not the `Create` action can be accessed
  def create?
    false
  end

  # Whether or not the `New` action can be accessed
  def new?
    create?
  end

  # Whether or not the `Update` action can be accessed
  def update?
    false
  end

  # Whether or not the `Edit` action can be accessed
  def edit?
    update?
  end

  # Whether or not the `Delete` action can be accessed
  def delete?
    false
  end
end
