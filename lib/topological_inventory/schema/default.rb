require "topological_inventory/schema/base"

module TopologicalInventory
  module Schema
    class Default < TopologicalInventory::Schema::Base
      def initialize_inventory_collections
        add_default_collection(:clusters)
        add_containers
        add_default_collection(:container_groups)
        add_default_collection(:container_images)
        add_default_collection(:container_nodes) { |b| add_secondary_refs_name(b) }
        add_default_collection(:container_projects) { |b| add_secondary_refs_name(b) }
        add_default_collection(:container_resource_quotas)
        add_default_collection(:container_templates)
        add_default_collection(:flavors)
        add_default_collection(:hosts)
        add_default_collection(:orchestration_stacks)
        add_default_collection(:service_instances)
        add_default_collection(:service_offering_icons)
        add_default_collection(:service_offerings)
        add_default_collection(:service_plans)
        add_default_collection(:source_regions)
        add_default_collection(:subscriptions)
        add_default_collection(:vms)
        add_default_collection(:volumes)
        add_default_collection(:volume_types)

        add_tagging_collection(:cluster_tags, :manager_ref => %i[cluster tag])
        add_tagging_collection(:container_group_tags, :manager_ref => [:container_group, :tag])
        add_tagging_collection(:container_image_tags, :manager_ref => [:container_image, :tag])
        add_tagging_collection(:container_node_tags, :manager_ref => [:container_node, :tag])
        add_tagging_collection(:container_project_tags, :manager_ref => [:container_project, :tag])
        add_tagging_collection(:container_template_tags, :manager_ref => [:container_template, :tag])
        add_tagging_collection(:host_tags, :manager_ref => %i[host tag])
        add_tagging_collection(:service_offering_tags, :manager_ref => [:service_offering, :tag])
        add_tagging_collection(:vm_tags, :manager_ref => [:vm, :tag])
        add_tags

        add_volume_attachments
        add_cross_link_vms
      end

      def targeted?
        true
      end

      private

      def add_default_collection(model)
        add_collection(model) do |builder|
          add_default_properties(builder)
          add_default_values(builder)
          yield builder if block_given?
        end
      end

      def add_default_properties(builder, manager_ref: [:source_ref])
        builder.add_properties(
          :manager_ref        => manager_ref,
          :strategy           => :local_db_find_missing_references,
          :retention_strategy => :archive
        )
      end

      def add_default_values(builder)
        builder.add_default_values(
          :source_id => ->(persister) { persister.manager.id },
          :tenant_id => ->(persister) { persister.manager.tenant_id },
        )
      end

      def add_secondary_refs_name(builder)
        builder.add_properties(:secondary_refs => {:by_name => [:name]})
      end

      def add_tagging_collection(model, manager_ref: [:source_ref])
        # TODO generate the manager_ref automatically?
        add_collection(model) do |builder|
          builder.add_properties(
            :manager_ref        => manager_ref,
            :strategy           => :local_db_find_missing_references,
            :retention_strategy => :destroy,
          )
        end
      end

      def add_containers
        add_collection(:containers) do |builder|
          add_default_properties(builder, manager_ref: [:container_group, :name])
          builder.add_default_values(:tenant_id => ->(persister) { persister.manager.tenant_id })
        end
      end

      def add_volume_attachments
        add_collection(:volume_attachments) do |builder|
          add_default_properties(builder, manager_ref: [:volume, :vm])
          builder.add_properties(:retention_strategy => :destroy)
          builder.add_default_values(:tenant_id => ->(persister) { persister.manager.tenant_id })
        end
      end

      def add_cross_link_vms
        add_collection(:cross_link_vms) do |builder|
          builder.add_properties(
            :arel        => Vm.where(:tenant => manager.tenant),
            :association => nil,
            :model_class => Vm,
            :name        => :cross_link_vms,
            :manager_ref => [:uid_ems],
            :strategy    => :local_db_find_references,
          )
        end
      end

      def add_tags
        add_collection(:tags) do |builder|
          builder.add_properties(
            :arel           => Tag.where(:tenant => manager.tenant),
            :association    => nil,
            :model_class    => Tag,
            :name           => :tags,
            :manager_ref    => [:name, :value, :namespace],
            :create_only    => true,
            :strategy       => :local_db_find_missing_references,
          )

          builder.add_default_values(
            :tenant_id => ->(persister) { persister.manager.tenant_id },
          )
        end
      end
    end
  end
end
