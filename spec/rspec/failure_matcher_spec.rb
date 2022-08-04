# frozen_string_literal: true

require 'spec_helper'
require 'glia/errors'
require 'dry/validation'

describe Salestation::RSpec::FailureMatcher do
  include Deterministic::Prelude
  Errors = Salestation::App::Errors

  it 'works end to end' do
    result = Deterministic::Result::Failure(
      Salestation::App::Errors::InvalidInput.new(
        errors: { name: ['is invalid'] },
        debug_message: 'debug message'
      )
    )

    expect(result).to be_failure
      .with_invalid_input
      .containing(hash_including(errors: { name: ['is invalid'] }))
  end

  it 'fails when result is not a failure' do
    expect(
      matcher.matches?(
        Success(Errors::Conflict.new(message: 'message'))
      )
    ).to eq(false)
  end

  it 'succeeds when result is a failure' do
    expect(
      matcher.matches?(
        Failure(Errors::Conflict.new(message: 'message'))
      )
    ).to eq(true)
  end

  it 'fails when error type is different' do
    expect(
      matcher.with_invalid_input.matches?(
        Failure(Errors::Conflict.new(message: 'message'))
      )
    ).to eq(false)
  end

  it 'succeeds when error type is the same' do
    expect(
      matcher.with_conflict.matches?(
        Failure(Errors::Conflict.new(message: 'message'))
      )
    ).to eq(true)
  end

  it 'fails when error contents are different' do
    expect(
      matcher.with_conflict.containing(hash_including(message: 'foo')).matches?(
        Failure(Errors::Conflict.new(message: 'bar'))
      )
    ).to eq(false)
  end

  it 'succeeds when error contents match' do
    expect(
      matcher.with_conflict.containing(hash_including(message: 'foo')).matches?(
        Failure(Errors::Conflict.new(message: 'foo'))
      )
    ).to eq(true)
  end

  it 'succeeds when error contents are exactly the same' do
    expect(
      matcher.with_conflict.containing(message: 'foo').matches?(
        Failure(Errors::Conflict.new(message: 'foo'))
      )
    ).to eq(true)
  end

  context 'when using with Glia Errors' do
    it 'succeeds when base error is the same' do
      failure = Failure(
        Errors::RequestedResourceNotFound.from(
          Glia::Errors::ResourceNotFoundError.new(resource: :user)
        )
      )

      expect(
        matcher
          .with_requested_resource_not_found
          .containing(Glia::Errors::ResourceNotFoundError.new(resource: :user))
          .matches?(failure)
      ).to eq(true)
    end

    it 'fails when base error has different contents' do
      failure = Failure(
        Errors::RequestedResourceNotFound.from(
          Glia::Errors::ResourceNotFoundError.new(resource: :article)
        )
      )

      expect(
        matcher
          .with_requested_resource_not_found
          .containing(Glia::Errors::ResourceNotFoundError.new(resource: :user))
          .matches?(failure)
      ).to eq(false)
    end
  end

  context 'when using with Glia Errors & dry-validation' do
    let(:schema) do
      Dry::Validation.Contract do
        params do
          required(:name).filled { type?(String) & min_size?(5) }
          required(:email).filled { type?(String) }
        end
      end
    end

    it 'succeeds when field name matches' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(glia_input_validation_error.on(:name))
          .matches?(failure)
      ).to eq(true)
    end

    it 'succeeds when one field type matches' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(glia_input_validation_error.on(:name).with_type(Glia::Errors::INVALID_VALUE_ERROR))
          .matches?(failure)
      ).to eq(true)
    end

    it 'succeeds when multiple field types match' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:name).with_type(Glia::Errors::INVALID_VALUE_ERROR)
              .on(:email).with_type(Glia::Errors::INVALID_VALUE_ERROR)
          )
          .matches?(failure)
      ).to eq(true)
    end

    it 'fails when one field type of multiple field types does not match' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:name).with_type(Glia::Errors::RESOURCE_LIMIT_EXCEEDED_ERROR)
              .on(:email).with_type(Glia::Errors::INVALID_VALUE_ERROR)
          )
          .matches?(failure)
      ).to eq(false)
    end

    it 'allows only some of the fields to have with_type matcher' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:name)
              .on(:email).with_type(Glia::Errors::INVALID_VALUE_ERROR)
          )
          .matches?(failure)
      ).to eq(true)
    end

    it 'fails when glia error field type does not match' do
      validation_result = schema.call(name: nil, email: nil)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(glia_input_validation_error.on(:name).with_type(Glia::Errors::RESOURCE_LIMIT_EXCEEDED_ERROR))
          .matches?(failure)
      ).to eq(false)
    end

    it 'succeeds when glia error field message matches' do
      validation_result = schema.call(name: nil, email: 1)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:email)
              .with_type(Glia::Errors::INVALID_TYPE_ERROR)
              .with_message('Email must be of type string')
          )
          .matches?(failure)
      ).to eq(true)
    end

    it 'fails when glia error field message does not match' do
      validation_result = schema.call(name: nil, email: 1)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:email)
              .with_type(Glia::Errors::INVALID_TYPE_ERROR)
              .with_message('whatever')
          )
          .matches?(failure)
      ).to eq(false)
    end

    it 'fails when one field message of multiple field messages does not match' do
      validation_result = schema.call(name: 1, email: 1)

      failure = Failure(
        Errors::InvalidInput.from(
          Glia::Errors.from_dry_validation_result(validation_result),
          errors: validation_result.errors.to_h,
          hints: {}
        )
      )

      expect(
        matcher
          .with_invalid_input
          .containing(
            glia_input_validation_error
              .on(:name).with_type(Glia::Errors::INVALID_TYPE_ERROR).with_message('Email must be of type string')
              .on(:email).with_type(Glia::Errors::INVALID_TYPE_ERROR).with_message('whatever')
          )
          .matches?(failure)
      ).to eq(false)
    end

    context 'with nested schema' do
      let(:schema) do
        Dry::Validation.Contract do
          params do
            required(:filters).hash do
              required(:name).filled { type?(String) & min_size?(5) }
              required(:email).filled { type?(String) }
            end
          end
        end
      end

      let(:validation_result) { schema.call(filters: {name: nil, email: 1}) }
      let(:failure) do
        Failure(
          Errors::InvalidInput.from(
            Glia::Errors.from_dry_validation_result(validation_result),
            errors: validation_result.errors.to_h,
            hints: {}
          )
        )
      end

      it 'succeeds when error is nested error' do
        expect(
          matcher
            .with_invalid_input
            .containing(
              glia_input_validation_error
                .on(:filters, :email)
                .with_type(Glia::Errors::INVALID_TYPE_ERROR)
                .with_message('Email must be of type string')
            )
            .matches?(failure)
        ).to eq(true)
      end

      it 'fails when error on a deeper level' do
        expect(
          matcher
            .with_invalid_input
            .containing(
              glia_input_validation_error
                .on(:filters, :deep, :email)
                .with_type(Glia::Errors::INVALID_TYPE_ERROR)
                .with_message('Email must be of type string')
            )
            .matches?(failure)
        ).to eq(false)
      end

      it 'fails when error on a parent level' do
        expect(
          matcher
            .with_invalid_input
            .containing(
              glia_input_validation_error
                .on(:email)
                .with_type(Glia::Errors::INVALID_TYPE_ERROR)
                .with_message('Email must be of type string')
            )
            .matches?(failure)
        ).to eq(false)
      end

      it 'fails when nested attribute does not exist' do
        expect(
          matcher
            .with_invalid_input
            .containing(
              glia_input_validation_error.on(:filters, :unknown)
            )
            .matches?(failure)
        ).to eq(false)
      end

      it 'fails when one field message of multiple field messages does not match' do
        validation_result = schema.call(filters: {name: nil, email: 1})

        failure = Failure(
          Errors::InvalidInput.from(
            Glia::Errors.from_dry_validation_result(validation_result),
            errors: validation_result.errors.to_h,
            hints: {}
          )
        )

        expect(
          matcher
            .with_invalid_input
            .containing(
              glia_input_validation_error
                .on(:filters, :name).with_type(Glia::Errors::INVALID_TYPE_ERROR).with_message('Email must be of type string')
                .on(:filters, :email).with_type(Glia::Errors::INVALID_TYPE_ERROR).with_message('whatever')
            )
            .matches?(failure)
        ).to eq(false)
      end
    end
  end

  def matcher
    described_class.new
  end
end
