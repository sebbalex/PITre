﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace DocsPaVO.utente.Repertori.RequestAndResponse
{
    [Serializable()]
    public class ChangeRepertorioStateRequest
    {

        public string CounterId { get; set; }

        public string RegistryId { get; set; }

        public string RfId { get; set; }

        public string IdAmm { get; set; }
    }
}
