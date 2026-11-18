CREATE TABLE IF NOT EXISTS schm_sp.user_inbox
(
    inbox_id bigserial,
    appl_id character varying COLLATE pg_catalog."default",
    appl_ref_no character varying COLLATE pg_catalog."default",
    service_id integer,
    task_id character varying COLLATE pg_catalog."default",
    form_id character varying COLLATE pg_catalog."default",
    current_process_id character varying COLLATE pg_catalog."default",
    user_token character varying COLLATE pg_catalog."default",
    service_name character varying COLLATE pg_catalog."default",
    task_name character varying COLLATE pg_catalog."default",
    appl_recieved_on timestamp without time zone,
    last_action_on timestamp without time zone,
    base_service_id integer,
    location_id integer,
    tenant_id character varying COLLATE pg_catalog."default",
    user_id integer,
    CONSTRAINT pkey PRIMARY KEY (inbox_id)
)

CREATE INDEX IF NOT EXISTS user_inbox_idx   ON schm_sp.user_inbox USING btree(appl_id, appl_ref_no, service_id, task_id, base_service_id,user_id, user_token );


-- Table: schm_sp.application_tracking

-- DROP TABLE IF EXISTS schm_sp.application_tracking;

CREATE TABLE IF NOT EXISTS schm_sp.application_tracking
(
    process_id character varying COLLATE pg_catalog."default" NOT NULL,
    appl_id character varying COLLATE pg_catalog."default" NOT NULL,
    appl_ref_no character varying COLLATE pg_catalog."default" NOT NULL,
    service_id integer NOT NULL,
    base_service_id integer NOT NULL,
    service_name character varying COLLATE pg_catalog."default",
    task_id character varying COLLATE pg_catalog."default" NOT NULL,
    task_name character varying COLLATE pg_catalog."default",
    previous_task_name character varying COLLATE pg_catalog."default",
    previous_task_id character varying COLLATE pg_catalog."default",
    action_code integer,
    action_taken character(1) COLLATE pg_catalog."default",
    applied_user_id bigint,
    beneficiary_user_name character varying COLLATE pg_catalog."default",
    apply_date date,
    holder_id character varying COLLATE pg_catalog."default",
    form_id character varying COLLATE pg_catalog."default",
    data_id character varying COLLATE pg_catalog."default",
    action_on timestamp with time zone,
    tenant_id character varying COLLATE pg_catalog."default",
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT application_tracking_pkey PRIMARY KEY (process_id)
)

-- Table: schm_sp.application_tracking_document

-- DROP TABLE IF EXISTS schm_sp.application_tracking_document;

CREATE TABLE IF NOT EXISTS schm_sp.application_tracking_document
(
    id bigint NOT NULL DEFAULT nextval('schm_sp.application_tracking_document_id_seq'::regclass),
    process_id character varying COLLATE pg_catalog."default" NOT NULL,
    document_id character varying COLLATE pg_catalog."default" NOT NULL,
    document_name character varying COLLATE pg_catalog."default",
    document_type character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT application_tracking_document_pkey PRIMARY KEY (id),
    CONSTRAINT fk_tracking_document_process FOREIGN KEY (process_id)
        REFERENCES schm_sp.application_tracking (process_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

-----NEXT ------------------------
-- Table: schm_sp.user_sentbox

-- DROP TABLE IF EXISTS schm_sp.user_sentbox;

CREATE TABLE schm_sp.user_sentbox
(
    id BIGSERIAL PRIMARY KEY,
    process_id CHARACTER VARYING NOT NULL,
    base_service_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    service_name CHARACTER VARYING,
    appl_id CHARACTER VARYING NOT NULL,
    appl_ref_no CHARACTER VARYING NOT NULL,
    submission_date TIMESTAMP WITH TIME ZONE,
    task_id CHARACTER VARYING,
    task_name CHARACTER VARYING,
    calledback BOOLEAN,
    holder_id CHARACTER VARYING NOT NULL,
    action_code INTEGER,
    action_user_id INTEGER,
    action_on TIMESTAMP WITH TIME ZONE,
    action_on_date TIMESTAMP WITH TIME ZONE,
    parent_ref_no CHARACTER VARYING,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tenant_id CHARACTER VARYING NOT NULL
);


CREATE TABLE schm_sp.application_tracking_holder
(
    id BIGSERIAL PRIMARY KEY,
    process_id CHARACTER VARYING NOT NULL,
    holder_id CHARACTER VARYING NOT NULL,
    location_id INTEGER,
    location_name CHARACTER VARYING,
    tenant_id CHARACTER VARYING NOT NULL,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

alter table schm_sp.application_tracking add column action_name character varying;

CREATE TABLE IF NOT EXISTS schm_sp.message_box
(
    message_id bigserial,
    application_id character varying COLLATE pg_catalog."default",
    appl_ref_no character varying COLLATE pg_catalog."default",
    service_id integer,
    base_service_id integer,
    process_id character varying COLLATE pg_catalog."default",
    associated_task_id character varying COLLATE pg_catalog."default",
    current_task_id character varying COLLATE pg_catalog."default",
    current_task_name character varying COLLATE pg_catalog."default",
    service_name character varying COLLATE pg_catalog."default",
    holder_id character varying COLLATE pg_catalog."default",
    location_id integer,
    allow_application_view boolean DEFAULT true,
    allow_history_view boolean DEFAULT true,
    is_read boolean DEFAULT false,
    read_on timestamp with time zone,
    auto_clear boolean DEFAULT false,
    cleared boolean DEFAULT false,
    cleared_on timestamp with time zone,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id character varying COLLATE pg_catalog."default",
    CONSTRAINT message_box_pkey PRIMARY KEY (message_id)
);

ALTER TABLE schm_sp.application_tracking_document ADD COLUMN view_permission JSONB;
ALTER TABLE IF EXISTS schm_sp.user_inbox ADD COLUMN is_priority boolean  NOT NULL DEFAULT false;


---------- inbox-sentbox-filter -----------------------------------
CREATE TABLE IF NOT EXISTS schm_sp.service_filter_config
(
    id bigserial NOT NULL,
    filter_id bigint NOT NULL,
    service_id bigint NOT NULL,
    base_service_id bigint NOT NULL,
	task_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr_form_id character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr_type character(1) COLLATE pg_catalog."default" NOT NULL,
    attr_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr_label character varying,
    filter_type character(1) NOT NULL;
    attr_order bigint NOT NULL,
    filter_condition character varying COLLATE pg_catalog."default",
    cr_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    up_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_filter_config_pkey PRIMARY KEY (id),
    CONSTRAINT unq_service_filter_config_filter_id UNIQUE (filter_id,task_id,attr_id,attr_type)
);


CREATE TABLE IF NOT EXISTS schm_sp.service_filter_input_data
(
    id bigserial NOT NULL,
    filter_id bigint NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr1_value character varying COLLATE pg_catalog."default",
    attr2_value character varying COLLATE pg_catalog."default",
    attr3_value character varying COLLATE pg_catalog."default",
    attr4_value character varying COLLATE pg_catalog."default",
    attr5_value character varying COLLATE pg_catalog."default",
    attr6_value character varying COLLATE pg_catalog."default",
    attr7_value character varying COLLATE pg_catalog."default",
    attr8_value character varying COLLATE pg_catalog."default",
    attr9_value character varying COLLATE pg_catalog."default",
    attr10_value character varying COLLATE pg_catalog."default",
    cr_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    up_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_filter_input_data_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS schm_sp.service_filter_output_data
(
    id bigserial NOT NULL,
    filter_id bigint NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr1_value character varying COLLATE pg_catalog."default",
    attr2_value character varying COLLATE pg_catalog."default",
    attr3_value character varying COLLATE pg_catalog."default",
    attr4_value character varying COLLATE pg_catalog."default",
    attr5_value character varying COLLATE pg_catalog."default",
    attr6_value character varying COLLATE pg_catalog."default",
    attr7_value character varying COLLATE pg_catalog."default",
    attr8_value character varying COLLATE pg_catalog."default",
    attr9_value character varying COLLATE pg_catalog."default",
    attr10_value character varying COLLATE pg_catalog."default",
    cr_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    up_date timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_filter_output_data_pkey PRIMARY KEY (id)
);

ALTER TABLE schm_sp.user_sentbox
    ALTER COLUMN action_on_date TYPE date;


-------------------- 14/09/2026---------------------


-- Table: schm_sp.applicant_inbox

-- DROP TABLE IF EXISTS schm_sp.applicant_inbox;

CREATE TABLE IF NOT EXISTS schm_sp.applicant_inbox
(
    id bigserial,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    application_ref_no character varying COLLATE pg_catalog."default",
    service_id integer,
    base_service_id integer,
    service_name character varying COLLATE pg_catalog."default",
    form_id character varying COLLATE pg_catalog."default",
    task_id character varying COLLATE pg_catalog."default" NOT NULL,
    task_name character varying COLLATE pg_catalog."default",
    current_process_id character varying COLLATE pg_catalog."default" NOT NULL,
    tenant_id character varying COLLATE pg_catalog."default",
    applied_by bigint,
    beneficiary_name character varying COLLATE pg_catalog."default",
    submission_to_same_official boolean NOT NULL DEFAULT false,
    requires_payment boolean NOT NULL DEFAULT false,
    requires_form boolean NOT NULL DEFAULT false,
    status character varying COLLATE pg_catalog."default",
    apply_date timestamp with time zone,
    cr_date timestamp with time zone,
    up_date timestamp with time zone,
    CONSTRAINT applicant_inbox_pkey PRIMARY KEY (id),
    CONSTRAINT applicant_inbox_current_process_id_key UNIQUE (current_process_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.applicant_inbox
    OWNER to postgres;
    
CREATE TABLE IF NOT EXISTS schm_sp.task_master
(
    id bigserial,
    task_id character varying COLLATE pg_catalog."default" NOT NULL,
    service_id integer NOT NULL,
    base_service_id integer NOT NULL,
    task_name character varying COLLATE pg_catalog."default" NOT NULL,
    tenant_id character varying COLLATE pg_catalog."default" NOT NULL,
    task_property jsonb,
    CONSTRAINT task_master_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS schm_sp.application_document_tiny_url
(
    id BIGSERIAL NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    reference_no character varying COLLATE pg_catalog."default",
    process_id character varying COLLATE pg_catalog."default" NOT NULL,
    tiny_url character varying COLLATE pg_catalog."default" NOT NULL,
    url_key character varying COLLATE pg_catalog."default" NOT NULL,
    access_flag boolean NOT NULL DEFAULT false,
    tenant_id character varying COLLATE pg_catalog."default" NOT NULL,
    cr_date timestamp with time zone NOT NULL,
    CONSTRAINT application_document_tiny_url_pkey
        PRIMARY KEY (id)
);


CREATE TABLE IF NOT EXISTS schm_sp.application_action_tiny_url
(
    id BIGSERIAL NOT NULL,
    application_id VARCHAR NOT NULL,
    service_id INTEGER NOT NULL,
    application_ref_no VARCHAR,
    tiny_url VARCHAR NOT NULL,
    url_key VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    cr_date TIMESTAMP WITH TIME ZONE NOT NULL,

    CONSTRAINT application_action_tiny_url_pkey
        PRIMARY KEY (id)
);


ALTER TABLE schm_sp.application_tracking
ADD COLUMN IF NOT EXISTS action_remarks VARCHAR(500);

ALTER TABLE schm_sp.application_document_tiny_url 
ADD COLUMN IF NOT EXISTS document_id VARCHAR;


------- Move to prod--------------
ALTER TABLE schm_sp.service_filter_config ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;


------------- correlation ------------------------


-- Table: schm_sp.service_correlation_attr_mapping

-- DROP TABLE IF EXISTS schm_sp.service_correlation_attr_mapping;

CREATE TABLE IF NOT EXISTS schm_sp.service_correlation_attr_mapping
(
    id BIGSERIAL NOT NULL ,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    task_id character varying COLLATE pg_catalog."default" NOT NULL,
    combination_id bigint NOT NULL,
    mapped_base_service_id bigint,
    mapped_service_id bigint,
    mapping_type character varying COLLATE pg_catalog."default" NOT NULL,
    mapped_set_id bigint NOT NULL,
    output_set_id character varying COLLATE pg_catalog."default",
    attr_id character varying COLLATE pg_catalog."default" NOT NULL,
    mapped_attr_id character varying COLLATE pg_catalog."default" NOT NULL,
    tenant_id character varying COLLATE pg_catalog."default",
    entity_id integer,
    cr_date timestamp with time zone NOT NULL,
    CONSTRAINT service_correlation_attr_mapping_pkey PRIMARY KEY (id),
    CONSTRAINT service_correlation_attr_mapping_uk UNIQUE (service_id, task_id, combination_id, attr_id, mapped_attr_id, mapping_type, mapped_set_id),
    CONSTRAINT service_correlation_attr_mapping_type_chk CHECK (mapping_type::text = ANY (ARRAY['I'::character varying, 'O'::character varying]::text[]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.service_correlation_attr_mapping
    OWNER to serviceplusrole;
	
	
	
	-- Table: schm_sp.service_correlation_mapping

-- DROP TABLE IF EXISTS schm_sp.service_correlation_mapping;

CREATE TABLE IF NOT EXISTS schm_sp.service_correlation_mapping
(
    id BIGSERIAL NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    task_id character varying COLLATE pg_catalog."default" NOT NULL,
    combination_id bigint NOT NULL,
    mapped_base_service_id bigint,
    mapped_service_id bigint,
    mapped_set_id bigint NOT NULL,
    output_set_id character varying COLLATE pg_catalog."default",
    source_type character(1) COLLATE pg_catalog."default" NOT NULL,
    priority integer,
    search_next boolean,
    appl_status integer NOT NULL,
    mappped_completed_task_id character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    entity_id integer,
    cr_date timestamp with time zone NOT NULL,
    CONSTRAINT service_correlation_mapping_pkey PRIMARY KEY (id),
    CONSTRAINT service_correlation_mapping_uk UNIQUE (service_id, task_id, combination_id, mapped_set_id, output_set_id),
    CONSTRAINT service_correlation_mapping_source_type_chk CHECK (source_type = ANY (ARRAY['S'::bpchar, 'E'::bpchar])),
    CONSTRAINT service_correlation_mapping_appl_status_chk CHECK (appl_status = ANY (ARRAY[1, 2, 3]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.service_correlation_mapping
    OWNER to serviceplusrole;
	
	
	
	-- Table: schm_sp.service_correlation_set

-- DROP TABLE IF EXISTS schm_sp.service_correlation_set;

CREATE TABLE IF NOT EXISTS schm_sp.service_correlation_set
(
    id BIGSERIAL NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    set_id bigint NOT NULL,
    source_type character(1) COLLATE pg_catalog."default" NOT NULL,
    skey character varying COLLATE pg_catalog."default",
    attr_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr_source character(1) COLLATE pg_catalog."default",
    attr_sort_order integer,
    set_type character varying COLLATE pg_catalog."default" NOT NULL,
    output_set_id character varying COLLATE pg_catalog."default",
    task_id character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    entity_id integer,
    cr_date timestamp with time zone NOT NULL,
    CONSTRAINT service_correlation_set_pkey PRIMARY KEY (id),
    CONSTRAINT service_correlation_set_uk UNIQUE (service_id, set_id, attr_id, set_type, output_set_id),
    CONSTRAINT service_correlation_set_source_type_chk CHECK (source_type = ANY (ARRAY['S'::bpchar, 'E'::bpchar]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.service_correlation_set
    OWNER to serviceplusrole;
	
	
	
	-- Table: schm_sp.service_correlation_set_order

-- DROP TABLE IF EXISTS schm_sp.service_correlation_set_order;

CREATE TABLE IF NOT EXISTS schm_sp.service_correlation_set_order
(
    id BIGSERIAL NOT NULL ,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    set_id bigint NOT NULL,
    attr_id character varying COLLATE pg_catalog."default" NOT NULL,
    attr_sort_order integer,
    attr_order_type character varying COLLATE pg_catalog."default" NOT NULL,
    tenant_id character varying COLLATE pg_catalog."default",
    entity_id integer,
    cr_date timestamp with time zone NOT NULL,
    CONSTRAINT service_correlation_set_order_pkey PRIMARY KEY (id),
    CONSTRAINT service_correlation_set_order_uk UNIQUE (service_id, set_id, attr_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.service_correlation_set_order
    OWNER to serviceplusrole;
    
<<<<<<< TrackingService/Scripts/Tables.sql
-- Table: schm_sp.application_attr_data

-- DROP TABLE IF EXISTS schm_sp.application_attr_data;

CREATE TABLE IF NOT EXISTS schm_sp.application_attr_data
(
    id BIGSERIAL NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    set_id bigint NOT NULL,
    output_set_id character varying COLLATE pg_catalog."default" NOT NULL,
    task_id character varying COLLATE pg_catalog."default",
    attr_1 character varying COLLATE pg_catalog."default",
    attr_1_value character varying COLLATE pg_catalog."default",
    attr_2 character varying COLLATE pg_catalog."default",
    attr_2_value character varying COLLATE pg_catalog."default",
    attr_3 character varying COLLATE pg_catalog."default",
    attr_3_value character varying COLLATE pg_catalog."default",
    attr_4 character varying COLLATE pg_catalog."default",
    attr_4_value character varying COLLATE pg_catalog."default",
    attr_5 character varying COLLATE pg_catalog."default",
    attr_5_value character varying COLLATE pg_catalog."default",
    attr_6 character varying COLLATE pg_catalog."default",
    attr_6_value character varying COLLATE pg_catalog."default",
    attr_7 character varying COLLATE pg_catalog."default",
    attr_7_value character varying COLLATE pg_catalog."default",
    attr_8 character varying COLLATE pg_catalog."default",
    attr_8_value character varying COLLATE pg_catalog."default",
    attr_9 character varying COLLATE pg_catalog."default",
    attr_9_value character varying COLLATE pg_catalog."default",
    attr_10 character varying COLLATE pg_catalog."default",
    attr_10_value character varying COLLATE pg_catalog."default",
    attr_11 character varying COLLATE pg_catalog."default",
    attr_11_value character varying COLLATE pg_catalog."default",
    attr_12 character varying COLLATE pg_catalog."default",
    attr_12_value character varying COLLATE pg_catalog."default",
    attr_13 character varying COLLATE pg_catalog."default",
    attr_13_value character varying COLLATE pg_catalog."default",
    attr_14 character varying COLLATE pg_catalog."default",
    attr_14_value character varying COLLATE pg_catalog."default",
    attr_15 character varying COLLATE pg_catalog."default",
    attr_15_value character varying COLLATE pg_catalog."default",
    attr_16 character varying COLLATE pg_catalog."default",
    attr_16_value character varying COLLATE pg_catalog."default",
    attr_17 character varying COLLATE pg_catalog."default",
    attr_17_value character varying COLLATE pg_catalog."default",
    attr_18 character varying COLLATE pg_catalog."default",
    attr_18_value character varying COLLATE pg_catalog."default",
    attr_19 character varying COLLATE pg_catalog."default",
    attr_19_value character varying COLLATE pg_catalog."default",
    attr_20 character varying COLLATE pg_catalog."default",
    attr_20_value character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    cr_date timestamp without time zone,
    up_date timestamp without time zone,
    CONSTRAINT pk_application_attr_data PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.application_attr_data
    OWNER to serviceplusrole;
-- Table: schm_sp.application_attr_fieldset_data

-- DROP TABLE IF EXISTS schm_sp.application_attr_fieldset_data;

CREATE TABLE IF NOT EXISTS schm_sp.application_attr_fieldset_data
(
    id BIGSERIAL NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    set_id bigint NOT NULL,
    output_set_id character varying COLLATE pg_catalog."default" NOT NULL,
    task_id character varying COLLATE pg_catalog."default",
    row_no integer,
    attr_1 character varying COLLATE pg_catalog."default",
    attr_1_value character varying COLLATE pg_catalog."default",
    attr_2 character varying COLLATE pg_catalog."default",
    attr_2_value character varying COLLATE pg_catalog."default",
    attr_3 character varying COLLATE pg_catalog."default",
    attr_3_value character varying COLLATE pg_catalog."default",
    attr_4 character varying COLLATE pg_catalog."default",
    attr_4_value character varying COLLATE pg_catalog."default",
    attr_5 character varying COLLATE pg_catalog."default",
    attr_5_value character varying COLLATE pg_catalog."default",
    attr_6 character varying COLLATE pg_catalog."default",
    attr_6_value character varying COLLATE pg_catalog."default",
    attr_7 character varying COLLATE pg_catalog."default",
    attr_7_value character varying COLLATE pg_catalog."default",
    attr_8 character varying COLLATE pg_catalog."default",
    attr_8_value character varying COLLATE pg_catalog."default",
    attr_9 character varying COLLATE pg_catalog."default",
    attr_9_value character varying COLLATE pg_catalog."default",
    attr_10 character varying COLLATE pg_catalog."default",
    attr_10_value character varying COLLATE pg_catalog."default",
    attr_11 character varying COLLATE pg_catalog."default",
    attr_11_value character varying COLLATE pg_catalog."default",
    attr_12 character varying COLLATE pg_catalog."default",
    attr_12_value character varying COLLATE pg_catalog."default",
    attr_13 character varying COLLATE pg_catalog."default",
    attr_13_value character varying COLLATE pg_catalog."default",
    attr_14 character varying COLLATE pg_catalog."default",
    attr_14_value character varying COLLATE pg_catalog."default",
    attr_15 character varying COLLATE pg_catalog."default",
    attr_15_value character varying COLLATE pg_catalog."default",
    attr_16 character varying COLLATE pg_catalog."default",
    attr_16_value character varying COLLATE pg_catalog."default",
    attr_17 character varying COLLATE pg_catalog."default",
    attr_17_value character varying COLLATE pg_catalog."default",
    attr_18 character varying COLLATE pg_catalog."default",
    attr_18_value character varying COLLATE pg_catalog."default",
    attr_19 character varying COLLATE pg_catalog."default",
    attr_19_value character varying COLLATE pg_catalog."default",
    attr_20 character varying COLLATE pg_catalog."default",
    attr_20_value character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    cr_date timestamp without time zone,
    up_date timestamp without time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.application_attr_fieldset_data
    OWNER to serviceplusrole;
	
	
	
	-- Table: schm_sp.application_attr_identifier_data

-- DROP TABLE IF EXISTS schm_sp.application_attr_identifier_data;

CREATE TABLE IF NOT EXISTS schm_sp.application_attr_identifier_data
(
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    service_id bigint NOT NULL,
    base_service_id bigint NOT NULL,
    set_id bigint NOT NULL,
    attr_hash bigint NOT NULL,
    attr_1_value character varying COLLATE pg_catalog."default",
    attr_2_value character varying COLLATE pg_catalog."default",
    attr_3_value character varying COLLATE pg_catalog."default",
    attr_4_value character varying COLLATE pg_catalog."default",
    attr_5_value character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    cr_date timestamp without time zone NOT NULL,
    up_date timestamp without time zone NOT NULL,
    CONSTRAINT pk_application_attr_identifier_data PRIMARY KEY (application_id, set_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.application_attr_identifier_data
    OWNER to serviceplusrole;
	
	
-- Table: schm_sp.application_set_order_attr_data

-- DROP TABLE IF EXISTS schm_sp.application_set_order_attr_data;

CREATE TABLE IF NOT EXISTS schm_sp.application_set_order_attr_data
(
    id BIGSERIAL NOT NULL,
    base_service_id bigint NOT NULL,
    service_id bigint NOT NULL,
    application_id character varying COLLATE pg_catalog."default" NOT NULL,
    set_id bigint NOT NULL,
    task_id character varying COLLATE pg_catalog."default",
    attr_1 character varying COLLATE pg_catalog."default",
    attr_1_value character varying COLLATE pg_catalog."default",
    attr_2 character varying COLLATE pg_catalog."default",
    attr_2_value character varying COLLATE pg_catalog."default",
    attr_3 character varying COLLATE pg_catalog."default",
    attr_3_value character varying COLLATE pg_catalog."default",
    attr_4 character varying COLLATE pg_catalog."default",
    attr_4_value character varying COLLATE pg_catalog."default",
    attr_5 character varying COLLATE pg_catalog."default",
    attr_5_value character varying COLLATE pg_catalog."default",
    attr_6 character varying COLLATE pg_catalog."default",
    attr_6_value character varying COLLATE pg_catalog."default",
    attr_7 character varying COLLATE pg_catalog."default",
    attr_7_value character varying COLLATE pg_catalog."default",
    attr_8 character varying COLLATE pg_catalog."default",
    attr_8_value character varying COLLATE pg_catalog."default",
    attr_9 character varying COLLATE pg_catalog."default",
    attr_9_value character varying COLLATE pg_catalog."default",
    attr_10 character varying COLLATE pg_catalog."default",
    attr_10_value character varying COLLATE pg_catalog."default",
    tenant_id character varying COLLATE pg_catalog."default",
    cr_date timestamp without time zone,
    up_date timestamp without time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS schm_sp.application_set_order_attr_data
    OWNER to serviceplusrole;
=======
-- Table: schm_sp.user_outbox

-- DROP TABLE IF EXISTS schm_sp.user_outbox;

CREATE TABLE IF NOT EXISTS schm_sp.user_outbox
(
    outbox_id bigserial,
    appl_id character varying COLLATE pg_catalog."default",
    appl_ref_no character varying COLLATE pg_catalog."default",
    service_id integer,
    task_id character varying COLLATE pg_catalog."default",
    form_id character varying COLLATE pg_catalog."default",
    current_process_id character varying COLLATE pg_catalog."default",
    user_token character varying COLLATE pg_catalog."default",
    service_name character varying COLLATE pg_catalog."default",
    task_name character varying COLLATE pg_catalog."default",
    appl_recieved_on timestamp with time zone,
    last_action_on timestamp with time zone,
    base_service_id integer,
    location_id integer,
    tenant_id character varying COLLATE pg_catalog."default",
    is_priority boolean NOT NULL DEFAULT false,
    CONSTRAINT user_outbox_pkey PRIMARY KEY (outbox_id)
);

CREATE INDEX IF NOT EXISTS user_outbox_idx ON schm_sp.user_outbox USING btree(appl_id, appl_ref_no, service_id, task_id, base_service_id, user_token);


ALTER TABLE schm_sp.task_master ADD COLUMN IF NOT EXISTS task_type integer;



ALTER TABLE schm_sp.application_tracking
ADD COLUMN IF NOT EXISTS due_date DATE;

ALTER TABLE schm_sp.user_inbox
ADD COLUMN IF NOT EXISTS due_date TIMESTAMP;