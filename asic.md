---
title: ASIC
permalink: /asic/
---

{% assign mydata=site.data %}

# ASIC Errors

<table>
    <thead>
        <th>Host</th>
        <th>Freq</th>
        {% for i in (1..4) %}
            <th>ASIC {{ i }}</th>
        {% endfor %}
    </thead>
    {% for file in mydata %}
        {% if file[0] contains 'stats'  %}
            {% assign myfiledata = file[1] | reverse %}
            {% for column in myfiledata limit:1 %}
            <tbody>
                <tr>
                    <td><a href="{{ site.baseurl }}/hist/{{ column.Host }}asic">{{ column.Host }}</a></td>
                    <td>{{ column.Freq }}</td>
                    <td>{{ column.ASIC_1 }}</td>
                    <td>{{ column.ASIC_2 }}</td>
                    <td>{{ column.ASIC_3 }}</td>
                    <td>{{ column.ASIC_4 }}</td>    
                </tr> 
            </tbody>
            {% endfor %}
        {% endif %}
    {% endfor %}
</table>

# ASIC Detail

<table>
    <thead>
        <th>Host</th>
        {% for i in (1..4) %}
            <th>ASIC {{ i }}</th>
        {% endfor %}
    </thead>
    {% for file in mydata %}
        {% if file[0] contains 'stats'  %}
            {% assign myfiledata = file[1] | reverse %}
            {% for column in myfiledata limit:1 %}
            <tbody>
                <tr>
                    <td>{{ column.Host }}</td>
                    <td>{{ column.ASIC_1_Status | split: '' | uniq }}</td>
                    <td>{{ column.ASIC_2_Status | split: '' | uniq }}</td>
                    <td>{{ column.ASIC_3_Status | split: '' | uniq }}</td>
                    <td>{{ column.ASIC_4_Status | split: '' | uniq }}</td>    
                </tr> 
            </tbody>
            {% endfor %}
        {% endif %}
    {% endfor %}
</table>
