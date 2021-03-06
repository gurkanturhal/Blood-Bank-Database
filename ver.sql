PGDMP                          y            postgres    13.1    13.1 Q    :           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ;           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            <           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            =           1262    13442    postgres    DATABASE     e   CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Turkish_Turkey.1254';
    DROP DATABASE postgres;
                postgres    false            >           0    0    DATABASE postgres    COMMENT     N   COMMENT ON DATABASE postgres IS 'default administrative connection database';
                   postgres    false    3133                        3079    16384 	   adminpack 	   EXTENSION     A   CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;
    DROP EXTENSION adminpack;
                   false            ?           0    0    EXTENSION adminpack    COMMENT     M   COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';
                        false    2            �            1255    24820 9   get_blood_type_inventory_percentage(character, refcursor)    FUNCTION     5  CREATE FUNCTION public.get_blood_type_inventory_percentage(character, refcursor) RETURNS refcursor
    LANGUAGE plpgsql
    AS $_$
DECLARE
reqType char(3) := $1;
results REFCURSOR := $2;
BEGIN
OPEN results FOR
SELECT TRUNC (
CAST (
( SELECT COUNT(gi.bbid) AS selectedBBID
FROM global_inventory gi INNER JOIN bloodbags bb ON gi.bbid = bb.bbid
WHERE bb.blood_type = reqType
AND gi.available = TRUE
) as decimal(5,2)
)
/
( SELECT COUNT(gi.bbid) AS allBBIDs
FROM global_inventory gi
WHERE gi.available = TRUE
)
* 100 ) AS BloodTypePercentage;
RETURN results;
END;
$_$;
 P   DROP FUNCTION public.get_blood_type_inventory_percentage(character, refcursor);
       public          postgres    false            �            1255    24819 2   get_persons_donation_records(character, refcursor)    FUNCTION     �  CREATE FUNCTION public.get_persons_donation_records(character, refcursor) RETURNS refcursor
    LANGUAGE plpgsql
    AS $_$
DECLARE
personID char(8) := $1;
results REFCURSOR := $2;
BEGIN
OPEN results FOR
SELECT dr.did, dr.lid, dr.donation_date, d.pid, d.peid,
d.nurse, d.amount_donated_CC, d.donation_type
FROM donation_records dr INNER JOIN donation d ON dr.did = d.did
WHERE personID = d.pid;
RETURN results;
END;
$_$;
 I   DROP FUNCTION public.get_persons_donation_records(character, refcursor);
       public          postgres    false            �            1255    24850    update_inventory_status()    FUNCTION     �   CREATE FUNCTION public.update_inventory_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF NEW.bbid is NOT NULL THEN
UPDATE global_inventory
SET available = FALSE
WHERE NEW.bbid = global_inventory.bbid;
END IF;
RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.update_inventory_status();
       public          postgres    false            �            1255    24851    update_next_donation_date()    FUNCTION     �  CREATE FUNCTION public.update_next_donation_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
waitDays integer;
donDate DATE := NEW.donation_date;
selectedDid char(8) := NEW.did;
BEGIN
IF selectedDid IS NOT NULL THEN
SELECT dt.frequency_days INTO waitDays
FROM donation d INNER JOIN donation_types dt ON d.donation_type = dt.type
INNER JOIN donation_records dr ON d.did = dr.did
WHERE dr.did = selectedDid;
-- update next safe donation date
UPDATE donor
SET nextSafeDonation = donDate + waitDays
WHERE donor.pid IN ( SELECT donor.pid
FROM donation d INNER JOIN donation_records dr ON d.did = dr.did
INNER JOIN donor ON donor.pid = d.pid
WHERE d.did = selectedDid
);
END IF;
RETURN NEW;
END;
$$;
 2   DROP FUNCTION public.update_next_donation_date();
       public          postgres    false            �            1259    24675 	   bloodbags    TABLE     �   CREATE TABLE public.bloodbags (
    bbid character(10) NOT NULL,
    donation_type text NOT NULL,
    quantity_cc numeric(5,2) NOT NULL,
    blood_type character(3) NOT NULL
);
    DROP TABLE public.bloodbags;
       public         heap    postgres    false            �            1259    24821    global_inventory    TABLE     �   CREATE TABLE public.global_inventory (
    bbid character(10) NOT NULL,
    lid character(6) NOT NULL,
    available boolean DEFAULT true
);
 $   DROP TABLE public.global_inventory;
       public         heap    postgres    false            �            1259    24854    availablebloodbags    VIEW     �   CREATE VIEW public.availablebloodbags AS
 SELECT gi.bbid,
    gi.lid,
    bb.blood_type,
    bb.donation_type,
    bb.quantity_cc
   FROM (public.global_inventory gi
     JOIN public.bloodbags bb ON ((gi.bbid = bb.bbid)))
  WHERE (gi.available = true);
 %   DROP VIEW public.availablebloodbags;
       public          postgres    false    214    214    214    208    208    208    208            �            1259    24728    donation    TABLE     �   CREATE TABLE public.donation (
    did character(8) NOT NULL,
    pid character(8) NOT NULL,
    peid character(8) NOT NULL,
    nurse character(8) NOT NULL,
    amount_donated_cc numeric(5,2) NOT NULL,
    donation_type text NOT NULL
);
    DROP TABLE public.donation;
       public         heap    postgres    false            �            1259    24779    donation_records    TABLE     �   CREATE TABLE public.donation_records (
    did character(8) NOT NULL,
    lid character(4) NOT NULL,
    donation_date date NOT NULL,
    bbid character(10) NOT NULL
);
 $   DROP TABLE public.donation_records;
       public         heap    postgres    false            �            1259    24647    donation_types    TABLE     d   CREATE TABLE public.donation_types (
    type text NOT NULL,
    frequency_days integer NOT NULL
);
 "   DROP TABLE public.donation_types;
       public         heap    postgres    false            �            1259    24584    donor    TABLE     7  CREATE TABLE public.donor (
    pid character(8) NOT NULL,
    blood_type character(3) NOT NULL,
    weightlbs integer NOT NULL,
    heightin integer NOT NULL,
    gender character(1) NOT NULL,
    nextsafedonation date,
    CONSTRAINT check_gender CHECK (((gender = 'M'::bpchar) OR (gender = 'F'::bpchar)))
);
    DROP TABLE public.donor;
       public         heap    postgres    false            �            1259    24696    location_codes    TABLE     `   CREATE TABLE public.location_codes (
    lc character(4) NOT NULL,
    descrip text NOT NULL
);
 "   DROP TABLE public.location_codes;
       public         heap    postgres    false            �            1259    24766 	   locations    TABLE     �   CREATE TABLE public.locations (
    lid character(6) NOT NULL,
    name text NOT NULL,
    lc character(4) NOT NULL,
    city text NOT NULL
);
    DROP TABLE public.locations;
       public         heap    postgres    false            �            1259    24858    locationinventories    VIEW     �  CREATE VIEW public.locationinventories AS
 SELECT gi.lid,
    sum(bb.quantity_cc) AS totquantity,
    bb.blood_type,
    bb.donation_type
   FROM ((public.global_inventory gi
     JOIN public.bloodbags bb ON ((gi.bbid = bb.bbid)))
     JOIN public.locations l ON ((gi.lid = l.lid)))
  GROUP BY bb.blood_type, bb.donation_type, gi.lid
  ORDER BY gi.lid DESC, (sum(bb.quantity_cc)) DESC;
 &   DROP VIEW public.locationinventories;
       public          postgres    false    208    208    208    208    211    214    214            �            1259    24609    nurse    TABLE     e   CREATE TABLE public.nurse (
    pid character(8) NOT NULL,
    years_experienced integer NOT NULL
);
    DROP TABLE public.nurse;
       public         heap    postgres    false            �            1259    24595    patient    TABLE       CREATE TABLE public.patient (
    pid character(8) NOT NULL,
    blood_type character(3) NOT NULL,
    need_status text NOT NULL,
    weightlbs integer NOT NULL,
    CONSTRAINT check_status CHECK (((need_status = 'high'::text) OR (need_status = 'low'::text)))
);
    DROP TABLE public.patient;
       public         heap    postgres    false            �            1259    24576    persons    TABLE     �   CREATE TABLE public.persons (
    pid character(8) NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    age integer NOT NULL
);
    DROP TABLE public.persons;
       public         heap    postgres    false            �            1259    24619    pre_exam    TABLE     �   CREATE TABLE public.pre_exam (
    peid character(8) NOT NULL,
    hemoglobin_gdl numeric(5,2) NOT NULL,
    temperature_f numeric(5,2) NOT NULL,
    blood_pressure character(8) NOT NULL,
    pulse_rate_bpm integer NOT NULL
);
    DROP TABLE public.pre_exam;
       public         heap    postgres    false            �            1259    24837    requests    TABLE     �   CREATE TABLE public.requests (
    rqid character(8) NOT NULL,
    lid character(6) NOT NULL,
    blood_type_requested text NOT NULL,
    date_requested date NOT NULL,
    quantity_requestedpints integer NOT NULL
);
    DROP TABLE public.requests;
       public         heap    postgres    false            �            1259    24655    transfusion    TABLE     �   CREATE TABLE public.transfusion (
    tid character(8) NOT NULL,
    pid character(8) NOT NULL,
    peid character(8) NOT NULL,
    nurse character(8) NOT NULL,
    amount_recieved_cc numeric(5,2) NOT NULL
);
    DROP TABLE public.transfusion;
       public         heap    postgres    false            �            1259    24799    transfusion_records    TABLE     �   CREATE TABLE public.transfusion_records (
    tid character(8) NOT NULL,
    lid character(4) NOT NULL,
    transfusion_date date NOT NULL,
    bbid character(10) NOT NULL
);
 '   DROP TABLE public.transfusion_records;
       public         heap    postgres    false            0          0    24675 	   bloodbags 
   TABLE DATA           Q   COPY public.bloodbags (bbid, donation_type, quantity_cc, blood_type) FROM stdin;
    public          postgres    false    208   m       2          0    24728    donation 
   TABLE DATA           [   COPY public.donation (did, pid, peid, nurse, amount_donated_cc, donation_type) FROM stdin;
    public          postgres    false    210   �m       4          0    24779    donation_records 
   TABLE DATA           I   COPY public.donation_records (did, lid, donation_date, bbid) FROM stdin;
    public          postgres    false    212   xn       .          0    24647    donation_types 
   TABLE DATA           >   COPY public.donation_types (type, frequency_days) FROM stdin;
    public          postgres    false    206   o       *          0    24584    donor 
   TABLE DATA           _   COPY public.donor (pid, blood_type, weightlbs, heightin, gender, nextsafedonation) FROM stdin;
    public          postgres    false    202   io       6          0    24821    global_inventory 
   TABLE DATA           @   COPY public.global_inventory (bbid, lid, available) FROM stdin;
    public          postgres    false    214   �o       1          0    24696    location_codes 
   TABLE DATA           5   COPY public.location_codes (lc, descrip) FROM stdin;
    public          postgres    false    209   Kp       3          0    24766 	   locations 
   TABLE DATA           8   COPY public.locations (lid, name, lc, city) FROM stdin;
    public          postgres    false    211   �p       ,          0    24609    nurse 
   TABLE DATA           7   COPY public.nurse (pid, years_experienced) FROM stdin;
    public          postgres    false    204   "r       +          0    24595    patient 
   TABLE DATA           J   COPY public.patient (pid, blood_type, need_status, weightlbs) FROM stdin;
    public          postgres    false    203   hr       )          0    24576    persons 
   TABLE DATA           B   COPY public.persons (pid, first_name, last_name, age) FROM stdin;
    public          postgres    false    201   �r       -          0    24619    pre_exam 
   TABLE DATA           g   COPY public.pre_exam (peid, hemoglobin_gdl, temperature_f, blood_pressure, pulse_rate_bpm) FROM stdin;
    public          postgres    false    205   ,t       7          0    24837    requests 
   TABLE DATA           l   COPY public.requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedpints) FROM stdin;
    public          postgres    false    215   u       /          0    24655    transfusion 
   TABLE DATA           P   COPY public.transfusion (tid, pid, peid, nurse, amount_recieved_cc) FROM stdin;
    public          postgres    false    207   �u       5          0    24799    transfusion_records 
   TABLE DATA           O   COPY public.transfusion_records (tid, lid, transfusion_date, bbid) FROM stdin;
    public          postgres    false    213   �u                  2606    24682    bloodbags bloodbags_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.bloodbags
    ADD CONSTRAINT bloodbags_pkey PRIMARY KEY (bbid);
 B   ALTER TABLE ONLY public.bloodbags DROP CONSTRAINT bloodbags_pkey;
       public            postgres    false    208            �           2606    24735    donation donation_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY public.donation
    ADD CONSTRAINT donation_pkey PRIMARY KEY (did);
 @   ALTER TABLE ONLY public.donation DROP CONSTRAINT donation_pkey;
       public            postgres    false    210            �           2606    24783 &   donation_records donation_records_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.donation_records
    ADD CONSTRAINT donation_records_pkey PRIMARY KEY (did);
 P   ALTER TABLE ONLY public.donation_records DROP CONSTRAINT donation_records_pkey;
       public            postgres    false    212            {           2606    24654 "   donation_types donation_types_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.donation_types
    ADD CONSTRAINT donation_types_pkey PRIMARY KEY (type);
 L   ALTER TABLE ONLY public.donation_types DROP CONSTRAINT donation_types_pkey;
       public            postgres    false    206            s           2606    24589    donor donor_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.donor
    ADD CONSTRAINT donor_pkey PRIMARY KEY (pid);
 :   ALTER TABLE ONLY public.donor DROP CONSTRAINT donor_pkey;
       public            postgres    false    202            �           2606    24826 &   global_inventory global_inventory_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.global_inventory
    ADD CONSTRAINT global_inventory_pkey PRIMARY KEY (bbid, lid);
 P   ALTER TABLE ONLY public.global_inventory DROP CONSTRAINT global_inventory_pkey;
       public            postgres    false    214    214            �           2606    24703 "   location_codes location_codes_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.location_codes
    ADD CONSTRAINT location_codes_pkey PRIMARY KEY (lc);
 L   ALTER TABLE ONLY public.location_codes DROP CONSTRAINT location_codes_pkey;
       public            postgres    false    209            �           2606    24773    locations locations_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (lid);
 B   ALTER TABLE ONLY public.locations DROP CONSTRAINT locations_pkey;
       public            postgres    false    211            w           2606    24613    nurse nurse_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.nurse
    ADD CONSTRAINT nurse_pkey PRIMARY KEY (pid);
 :   ALTER TABLE ONLY public.nurse DROP CONSTRAINT nurse_pkey;
       public            postgres    false    204            u           2606    24603    patient patient_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (pid);
 >   ALTER TABLE ONLY public.patient DROP CONSTRAINT patient_pkey;
       public            postgres    false    203            q           2606    24583    persons persons_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (pid);
 >   ALTER TABLE ONLY public.persons DROP CONSTRAINT persons_pkey;
       public            postgres    false    201            y           2606    24623    pre_exam pre_exam_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.pre_exam
    ADD CONSTRAINT pre_exam_pkey PRIMARY KEY (peid);
 @   ALTER TABLE ONLY public.pre_exam DROP CONSTRAINT pre_exam_pkey;
       public            postgres    false    205            �           2606    24844    requests requests_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (rqid);
 @   ALTER TABLE ONLY public.requests DROP CONSTRAINT requests_pkey;
       public            postgres    false    215            }           2606    24659    transfusion transfusion_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.transfusion
    ADD CONSTRAINT transfusion_pkey PRIMARY KEY (tid);
 F   ALTER TABLE ONLY public.transfusion DROP CONSTRAINT transfusion_pkey;
       public            postgres    false    207            �           2606    24803 ,   transfusion_records transfusion_records_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.transfusion_records
    ADD CONSTRAINT transfusion_records_pkey PRIMARY KEY (tid);
 V   ALTER TABLE ONLY public.transfusion_records DROP CONSTRAINT transfusion_records_pkey;
       public            postgres    false    213            �           2620    24852 3   transfusion_records update_inventory_status_trigger    TRIGGER     �   CREATE TRIGGER update_inventory_status_trigger BEFORE INSERT ON public.transfusion_records FOR EACH ROW EXECUTE FUNCTION public.update_inventory_status();
 L   DROP TRIGGER update_inventory_status_trigger ON public.transfusion_records;
       public          postgres    false    220    213            �           2620    24853 7   donation_records update_next_safe_donation_date_trigger    TRIGGER     �   CREATE TRIGGER update_next_safe_donation_date_trigger BEFORE INSERT ON public.donation_records FOR EACH ROW EXECUTE FUNCTION public.update_inventory_status();
 P   DROP TRIGGER update_next_safe_donation_date_trigger ON public.donation_records;
       public          postgres    false    220    212            �           2606    24683 &   bloodbags bloodbags_donation_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bloodbags
    ADD CONSTRAINT bloodbags_donation_type_fkey FOREIGN KEY (donation_type) REFERENCES public.donation_types(type);
 P   ALTER TABLE ONLY public.bloodbags DROP CONSTRAINT bloodbags_donation_type_fkey;
       public          postgres    false    206    2939    208            �           2606    24751 $   donation donation_donation_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.donation
    ADD CONSTRAINT donation_donation_type_fkey FOREIGN KEY (donation_type) REFERENCES public.donation_types(type);
 N   ALTER TABLE ONLY public.donation DROP CONSTRAINT donation_donation_type_fkey;
       public          postgres    false    210    2939    206            �           2606    24746    donation donation_nurse_fkey    FK CONSTRAINT     z   ALTER TABLE ONLY public.donation
    ADD CONSTRAINT donation_nurse_fkey FOREIGN KEY (nurse) REFERENCES public.nurse(pid);
 F   ALTER TABLE ONLY public.donation DROP CONSTRAINT donation_nurse_fkey;
       public          postgres    false    204    210    2935            �           2606    24741    donation donation_peid_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.donation
    ADD CONSTRAINT donation_peid_fkey FOREIGN KEY (peid) REFERENCES public.pre_exam(peid);
 E   ALTER TABLE ONLY public.donation DROP CONSTRAINT donation_peid_fkey;
       public          postgres    false    2937    205    210            �           2606    24736    donation donation_pid_fkey    FK CONSTRAINT     v   ALTER TABLE ONLY public.donation
    ADD CONSTRAINT donation_pid_fkey FOREIGN KEY (pid) REFERENCES public.donor(pid);
 D   ALTER TABLE ONLY public.donation DROP CONSTRAINT donation_pid_fkey;
       public          postgres    false    2931    210    202            �           2606    24794 +   donation_records donation_records_bbid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.donation_records
    ADD CONSTRAINT donation_records_bbid_fkey FOREIGN KEY (bbid) REFERENCES public.bloodbags(bbid);
 U   ALTER TABLE ONLY public.donation_records DROP CONSTRAINT donation_records_bbid_fkey;
       public          postgres    false    208    212    2943            �           2606    24784 *   donation_records donation_records_did_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.donation_records
    ADD CONSTRAINT donation_records_did_fkey FOREIGN KEY (did) REFERENCES public.donation(did);
 T   ALTER TABLE ONLY public.donation_records DROP CONSTRAINT donation_records_did_fkey;
       public          postgres    false    210    212    2947            �           2606    24789 *   donation_records donation_records_lid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.donation_records
    ADD CONSTRAINT donation_records_lid_fkey FOREIGN KEY (lid) REFERENCES public.locations(lid);
 T   ALTER TABLE ONLY public.donation_records DROP CONSTRAINT donation_records_lid_fkey;
       public          postgres    false    212    211    2949            �           2606    24590    donor donor_pid_fkey    FK CONSTRAINT     r   ALTER TABLE ONLY public.donor
    ADD CONSTRAINT donor_pid_fkey FOREIGN KEY (pid) REFERENCES public.persons(pid);
 >   ALTER TABLE ONLY public.donor DROP CONSTRAINT donor_pid_fkey;
       public          postgres    false    2929    201    202            �           2606    24827 +   global_inventory global_inventory_bbid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.global_inventory
    ADD CONSTRAINT global_inventory_bbid_fkey FOREIGN KEY (bbid) REFERENCES public.bloodbags(bbid);
 U   ALTER TABLE ONLY public.global_inventory DROP CONSTRAINT global_inventory_bbid_fkey;
       public          postgres    false    2943    214    208            �           2606    24832 *   global_inventory global_inventory_lid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.global_inventory
    ADD CONSTRAINT global_inventory_lid_fkey FOREIGN KEY (lid) REFERENCES public.locations(lid);
 T   ALTER TABLE ONLY public.global_inventory DROP CONSTRAINT global_inventory_lid_fkey;
       public          postgres    false    2949    211    214            �           2606    24774    locations locations_lc_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_lc_fkey FOREIGN KEY (lc) REFERENCES public.location_codes(lc);
 E   ALTER TABLE ONLY public.locations DROP CONSTRAINT locations_lc_fkey;
       public          postgres    false    211    209    2945            �           2606    24614    nurse nurse_pid_fkey    FK CONSTRAINT     r   ALTER TABLE ONLY public.nurse
    ADD CONSTRAINT nurse_pid_fkey FOREIGN KEY (pid) REFERENCES public.persons(pid);
 >   ALTER TABLE ONLY public.nurse DROP CONSTRAINT nurse_pid_fkey;
       public          postgres    false    201    2929    204            �           2606    24604    patient patient_pid_fkey    FK CONSTRAINT     v   ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pid_fkey FOREIGN KEY (pid) REFERENCES public.persons(pid);
 B   ALTER TABLE ONLY public.patient DROP CONSTRAINT patient_pid_fkey;
       public          postgres    false    201    203    2929            �           2606    24845    requests requests_lid_fkey    FK CONSTRAINT     z   ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_lid_fkey FOREIGN KEY (lid) REFERENCES public.locations(lid);
 D   ALTER TABLE ONLY public.requests DROP CONSTRAINT requests_lid_fkey;
       public          postgres    false    2949    215    211            �           2606    24670 "   transfusion transfusion_nurse_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transfusion
    ADD CONSTRAINT transfusion_nurse_fkey FOREIGN KEY (nurse) REFERENCES public.nurse(pid);
 L   ALTER TABLE ONLY public.transfusion DROP CONSTRAINT transfusion_nurse_fkey;
       public          postgres    false    2935    204    207            �           2606    24665 !   transfusion transfusion_peid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transfusion
    ADD CONSTRAINT transfusion_peid_fkey FOREIGN KEY (peid) REFERENCES public.pre_exam(peid);
 K   ALTER TABLE ONLY public.transfusion DROP CONSTRAINT transfusion_peid_fkey;
       public          postgres    false    205    2937    207            �           2606    24660     transfusion transfusion_pid_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.transfusion
    ADD CONSTRAINT transfusion_pid_fkey FOREIGN KEY (pid) REFERENCES public.patient(pid);
 J   ALTER TABLE ONLY public.transfusion DROP CONSTRAINT transfusion_pid_fkey;
       public          postgres    false    207    2933    203            �           2606    24814 1   transfusion_records transfusion_records_bbid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transfusion_records
    ADD CONSTRAINT transfusion_records_bbid_fkey FOREIGN KEY (bbid) REFERENCES public.bloodbags(bbid);
 [   ALTER TABLE ONLY public.transfusion_records DROP CONSTRAINT transfusion_records_bbid_fkey;
       public          postgres    false    2943    208    213            �           2606    24809 0   transfusion_records transfusion_records_lid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transfusion_records
    ADD CONSTRAINT transfusion_records_lid_fkey FOREIGN KEY (lid) REFERENCES public.locations(lid);
 Z   ALTER TABLE ONLY public.transfusion_records DROP CONSTRAINT transfusion_records_lid_fkey;
       public          postgres    false    211    213    2949            �           2606    24804 0   transfusion_records transfusion_records_tid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transfusion_records
    ADD CONSTRAINT transfusion_records_tid_fkey FOREIGN KEY (tid) REFERENCES public.transfusion(tid);
 Z   ALTER TABLE ONLY public.transfusion_records DROP CONSTRAINT transfusion_records_tid_fkey;
       public          postgres    false    2941    207    213            0   �   x�u�K
� �ᵞ�}N��e� Z�Irgt����ۏf�`�#�y?Y��s�F��qKO��~�3��H�,�V>�e���:X���-,�>CW����Ѷ	�p��a��@�V��"f}F)�P�M�      2   �   x�}���0D��+��mKW��x�Bҽa0B��+�P��&d��N'R������
�I��WZ���{y樢o dJ�
���q|V| +@�tC?]{qN�	����G2�� ۊ��'= ��Z� 0�pY �w�ks �n'%� ���P�� �i�OH�� �\�`wR��p��RO�|�      4   �   x�u��� г��(��0�RBN�_CDD\x#-{`}��v	#gb,�����&}e3�F�)n
!��nb7�M%3��m�cs�Lv�&93���9m��2�J�_��7�<�c��I��Cny�0��!@�z�����S��o����Oe      .   :   x��I,�M�4��
�/O-RJM�444�r���O�45�
�I,I�I-)�4����� ze�      *   w   x�M�1�0�����;�$�R��x�_���Jɛ��ԡh���_�t�|k�l�Cu� ��	a�����T��!�:HQf��X[�'r$j�����:���w�=��OJ�0&0      6   K   x�KJ2R� NS0U�d34���`Qg�E�9u��XČ0�cC3/(f�E��- 13,b`�X� �-O      1   �   x�]�A
�0D��)r��k#T-��	1�4��H���q%��73�2ρoO�l�OB�$j� ��q�h:V�IT_/.B������J�'<Ƭ��r�<����=/��O��"��
�2��?Xڎ;e�ߙ9�R6c��O�oF3퓷䖣�r��rJ�      3     x�uP�j1}N�b���~y�T�BVEE(�%�6���L�����D�y�9�9G?A�����y�0�b�04GP���'��8�!H}S8�k�ڷL�9
�CE�s�xQ-�+1�}g7�;v�Y�=k��]czN*3L� �7�\ʞ��F1X���=I�\<'�Z_go�/�x��u[Pk�l"#%����6��Aa�mK�F�SP'P���ze5�P�/�1�5�-��D���$
�����#��8��p����p����f�x��u��%���j���WR�o���      ,   6   x�+0R NC#�ۜ��� �62͠�@�9�m	dZ@��lK�)1z\\\ k��      +   J   x�+0T NmΜ�rNCs#�c��#L���&�͙����ihd�U`1��	��� (h���Ђ+F��� ��'      )   Z  x�U�An�0E��S�N� �J�V�EꆍF�±�q(JO�qb$���<��M�|?xw��
mO�`!˅�y��h��E&|��nP���]��I��{$F]~�8)�SB�=�VY�P9c��8�(��ߢ���=F0~��Z��#|h{b��/ط�S�ʞ!�s9K�0�(عo�>�qRN��R�lqV(#�*�K�� ��|;��r�����P7k�n�|ά�)\v��I#9�KfSmxS֪����Xƛ�?ŵ6f�V,���R�i� �tq5^m6ht��/�L[త��K���'ʒ�?ƒyb��#�ϒ�Z7g�հ��O(n%��c+���Q��Q�'I�      -   �   x�e�;�0Dk�9�Bt���s�*�>#;.4�,���/��)��41��R�K����(�P@�$�j -Y �B���(�����u����^ُ< 
y�P��P0\-L���hс����5�JaΠ� a��!�6�f���q�{=b<x�2���@�)�
q��C�:�O��� �)(: sO% �=Đz_n�m�����ef      7   e   x�m�1�0��N�nj�V����K�����$����O-<���/3��@0��Zd�d&|�n$��#Q;I���#-����P6��x�F� ��4s/�� �k+{      /   Z   x�+1T �8#��0�����p����p��P�	T��������� ��0���p��P���!�TS�R#�R#T@M����� ~$�      5   \   x�e��� гL�4|����zr�Oi#\�D�_�L��mKRAc�Ic�$�T7��(f�0e�cFa��9ÈeQ3-Lݻ���Y�9��gj     