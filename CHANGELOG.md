# Changelog

Will try to document notable changes and additions in this document.

## 0.2.0 - 2022-06-08

Significant updates but no breaking changes.

#### Named Validators

Previously, we could only use one validator per controller. This problem has been removed by allowing us to name particular sanitizer/validators and then call those specific validators from the validate/populate blocks.

Example
```ruby
  def action
    validate(:foo) do |validator|

    end

    populate(:foo) do |input|

    end
  end
```

Non-named validators will now be known as "default" validators for the class.

`errors` can also be accessed by name. `errors?` checks for any error.

#### Iterating validate / populate blocks

There are times when we don't want to just upload one model at a time, but group a whole list of items into a single web request. The `validate_for_each` and `populate_for_each` blocks have been added to address that.

The `errors` method will also reflect this list by returning the relevant error objects at the appropriate index / key.

All the `populate_for_each` entries share a single transaction, so they will all be rolled back when one fails (when supported by the DB)

#### Other Updates

- Significant testing has been added.
- Allow `populate` blocks to exist within `populate` blocks to share a single transaction but different serializers.
- `populate_once` block to allow a single population in a `populate_for_each` block.
- `all_errors` returns the entire error object